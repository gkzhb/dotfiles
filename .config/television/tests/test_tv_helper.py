#!/usr/bin/env python3
"""Isolated Git/argv tests; no real service or clipboard mutations."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import pty
import select
import shutil
import subprocess
import sys
import tempfile
import time
import tomllib
import unittest
from unittest.mock import patch

TV_ROOT = Path(__file__).resolve().parents[1]
HELPER = TV_ROOT / 'tv-helper.py'
spec = importlib.util.spec_from_file_location('tv_helper', HELPER)
h = importlib.util.module_from_spec(spec)
spec.loader.exec_module(h)


class HelperTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='tv safe test ')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.repo = self.root / 'repo'
        self.repo.mkdir()
        self.env = dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_SYSTEM=os.devnull)
        self.git('init', '-q')
        self.git('config', 'user.name', 'Test')
        self.git('config', 'user.email', 'test@example.invalid')
        (self.repo / 'sub').mkdir()
        (self.repo / 'tracked.txt').write_text('old\n')
        (self.repo / 'sub/known.txt').write_text('old\n')
        self.git('add', '.')
        self.git('commit', '-qm', 'fixture')

    def git(self, *args):
        return subprocess.run(['git', *args], cwd=self.repo, env=self.env,
                              check=True, capture_output=True).stdout

    def helper(self, *args, cwd=None, env=None, success=True):
        result = subprocess.run([sys.executable, str(HELPER), *args], cwd=cwd or self.repo,
                                env=env or self.env, capture_output=True, timeout=10)
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def rows(self, command, cwd=None):
        return [row.split('\t', 1) for row in self.helper(command, cwd=cwd).stdout.decode().splitlines()]

    def test_changed_paths_from_subdirectory_and_special_names(self):
        names = ['中文.txt', "quote'; touch SAFE_PROBE; #", 'new\nline.txt', 'tab\tfile.txt',
                 '[glob].txt', '-option.txt', 'sub/new.txt']
        for name in names:
            (self.repo / name).write_text('untracked-content\n')
        (self.repo / 'tracked.txt').write_text('new\n')
        (self.repo / 'sub/known.txt').write_text('new\n')
        rows = self.rows('changed-list', cwd=self.repo / 'sub')
        values = [h.decode(t) for t, _ in rows]
        self.assertEqual({v[1] for v in values}, set(names + ['tracked.txt', 'sub/known.txt']))
        self.assertTrue(all(v[0] == str(self.repo) for v in values))
        for value, _ in rows:
            output = self.helper('changed-preview', value, cwd=self.repo / 'sub').stdout
            self.assertTrue(output)
        self.assertFalse((self.repo / 'SAFE_PROBE').exists())

    def test_no_duplicate_staged_and_unstaged_paths(self):
        (self.repo / 'tracked.txt').write_text('stage\n')
        self.git('add', 'tracked.txt')
        (self.repo / 'tracked.txt').write_text('unstaged\n')
        self.assertEqual(len(self.rows('changed-list')), 1)

    def test_editor_arguments_are_not_interpreted(self):
        name = "--odd '; touch SAFE_PROBE; #.txt"
        (self.repo / name).write_text('test')
        record = self.root / 'editor.json'
        executable = self.root / 'editor stub.py'
        executable.write_text('import sys,json,pathlib\npathlib.Path(sys.argv[1]).write_text(json.dumps(sys.argv[2:]))\n')
        env = dict(self.env, EDITOR=f'{sys.executable} "{executable}" "{record}" --wait')
        self.helper('changed-edit', h.token([str(self.repo), name]), env=env)
        self.assertEqual(json.loads(record.read_text()), ['--wait', '--', str(self.repo / name)])
        self.assertFalse((self.repo / 'SAFE_PROBE').exists())

    def test_deleted_file_not_recreated(self):
        (self.repo / 'tracked.txt').unlink()
        self.helper('changed-edit', h.token([str(self.repo), 'tracked.txt']), success=False)
        self.assertFalse((self.repo / 'tracked.txt').exists())

    def test_untracked_restore_is_refused(self):
        (self.repo / 'new').write_text('keep')
        self.helper('changed-restore', h.token([str(self.repo), 'new']), success=False)
        self.assertEqual((self.repo / 'new').read_text(), 'keep')

    def test_restore_requires_confirmation_and_uses_literal_argv(self):
        value = h.token([str(self.repo), '[glob].txt'])
        with patch.object(h, 'git', return_value=b'yes') as git, patch.object(h, 'confirm', side_effect=h.Error('Cancelled')):
            with self.assertRaises(h.Error):
                h.changed_action('restore', value)
            self.assertEqual(git.call_count, 1)
        with patch.object(h, 'git', return_value=b'yes') as git, patch.object(h, 'confirm'):
            h.changed_action('restore', value)
            self.assertEqual(git.call_args.args, ('restore', '--worktree', '--', '[glob].txt'))

    def test_real_terminal_restore_requires_exact_word(self):
        path = self.repo / 'tracked.txt'
        value = h.token([str(self.repo), 'tracked.txt'])
        for answer, expected in [('NO', 'modified\n'), ('RESTORE', 'old\n')]:
            path.write_text('modified\n')
            pid, fd = pty.fork()
            if pid == 0:
                os.chdir(self.repo)
                os.execve(sys.executable, [sys.executable, str(HELPER), 'changed-restore', value], self.env)
            output = b''
            deadline = time.monotonic() + 5
            sent = False
            try:
                while time.monotonic() < deadline:
                    ready, _, _ = select.select([fd], [], [], 0.1)
                    if ready:
                        try:
                            chunk = os.read(fd, 4096)
                        except OSError:
                            break
                        if not chunk:
                            break
                        output += chunk
                    if b'Type RESTORE to continue:' in output and not sent:
                        os.write(fd, answer.encode() + b'\n')
                        sent = True
                self.assertTrue(sent, output)
            finally:
                # If confirmation failed to complete, never leave a child waiting.
                try:
                    os.kill(pid, 9)
                except ProcessLookupError:
                    pass
                os.waitpid(pid, 0)
                os.close(fd)
            self.assertEqual(path.read_text(), expected, output)

    def test_invalid_tokens_and_traversal_refused(self):
        for value in ['not-hex', "';touch INJECTED", h.token(['relative', 'file']),
                      h.token([str(self.repo), '../outside'])]:
            self.helper('changed-preview', value, success=False)
        for sha in ['HEAD', '--all', 'abc', '1' * 40 + ';id']:
            self.helper('log-preview', sha, success=False)

    def test_worktrees_spaces_quotes_newlines_and_detached(self):
        worktree = self.root / "work tree'\nnext"
        self.git('worktree', 'add', '-q', '--detach', str(worktree))
        rows = self.rows('worktree-list')
        paths = {h.decode(value) for value, _ in rows}
        self.assertEqual(paths, {str(self.repo), str(worktree)})
        for value, _ in rows:
            self.helper('worktree-preview', value)
            self.assertEqual(self.helper('worktree-path', value).stdout,
                             os.fsencode(h.decode(value)) + b'\0')

    def test_log_only_outputs_hash_tokens_and_confirms_mutations(self):
        rows = self.rows('log-list')
        self.assertEqual(len(rows), 1)
        sha = rows[0][0]
        self.assertRegex(sha, r'^[0-9a-f]{40}$')
        self.helper('log-preview', sha)
        for action in ['checkout', 'cherry-pick']:
            with patch.object(h, 'confirm', side_effect=h.Error('Cancelled')), patch.object(h.subprocess, 'call') as call:
                with self.assertRaises(h.Error):
                    h.log_action(action, sha)
                call.assert_not_called()

    @unittest.skipUnless(shutil.which('fish'), 'fish required')
    def test_fish_worktree_changes_parent_directory(self):
        destination = self.root / "directory with 'quote\nline"
        destination.mkdir()
        home = self.root / 'home'
        config = home / '.config/television'
        config.mkdir(parents=True)
        (config / 'tv-helper.py').symlink_to(HELPER)
        bin_dir = self.root / 'bin'
        bin_dir.mkdir()
        fake_tv = bin_dir / 'tv'
        fake_tv.write_text(f'#!{sys.executable}\nprint({h.token(str(destination))!r})\n')
        fake_tv.chmod(0o755)
        function = TV_ROOT.parent / 'fish/functions/tv-worktree.fish'
        env = dict(self.env, HOME=str(home), PATH=str(bin_dir) + os.pathsep + os.environ['PATH'])
        result = subprocess.run(['fish', '--no-config', '-c',
                                 'source "$argv[1]"; tv-worktree; or exit 1; printf "%s\\\\0" "$PWD"',
                                 str(function)], env=env, cwd=self.repo, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, os.fsencode(destination) + b'\0')

    def test_clipboard_not_tmux(self):
        with patch.object(h.shutil, 'which', side_effect=lambda exe: '/bin/pbcopy' if exe == 'pbcopy' else None), patch.object(h, 'run') as run:
            h.log_action('copy', 'a' * 40)
            run.assert_called_once_with(['pbcopy'], data=b'a' * 40 + b'\n')

    def test_gui_service_list_preserves_label_and_pid(self):
        output = b'gui/501 = {\n\tservices = {\n\t 42 -9 com.example.test\n\t 0 (pe) com.example.other\n\t}\n}\n'
        with patch.object(h, 'run', return_value=output) as run, contextlib.redirect_stdout(io.StringIO()) as out:
            h.service_list()
        run.assert_called_once_with(['launchctl', 'print', f'gui/{os.getuid()}'])
        rows = [line.split('\t', 1) for line in out.getvalue().splitlines()]
        self.assertEqual([h.decode(v) for v, _ in rows], ['com.example.test', 'com.example.other'])

    def test_service_actions_fixed_domain_and_confirmation(self):
        target = f'gui/{os.getuid()}/com.example.test'
        commands = {'start': ['kickstart', target], 'stop': ['kill', 'SIGTERM', target],
                    'restart': ['kickstart', '-k', target], 'enable': ['enable', target],
                    'disable': ['disable', target]}
        for action, command in commands.items():
            with patch.object(h, 'confirm') as confirm, patch.object(h.subprocess, 'call', return_value=0) as call:
                h.service_action(action, h.token('com.example.test'))
                confirm.assert_called_once()
                call.assert_called_once_with(['launchctl', *command])
        with patch.object(h, 'confirm', side_effect=h.Error('Cancelled')), patch.object(h.subprocess, 'call') as call:
            with self.assertRaises(h.Error):
                h.service_action('restart', h.token('com.example.test'))
            call.assert_not_called()

    def test_nix_plist_not_edited(self):
        with patch.object(h, 'run', return_value=b' path = /nix/store/abc/service.plist\n'), patch.object(h.os.path, 'isfile', return_value=True), patch.object(h.os.path, 'realpath', return_value='/nix/store/abc/service.plist'), patch.object(h, 'editor') as editor:
            with self.assertRaises(h.Error):
                h.service_action('plist', h.token('com.example.test'))
            editor.assert_not_called()

    def test_channel_commands_parse_with_fish_and_only_insert_safe_tokens(self):
        for name in ['git-changed-files', 'git-log', 'git-worktree', 'launchd']:
            cfg = tomllib.loads((TV_ROOT / 'cable' / (name + '.toml')).read_text())
            self.assertIn('python3', cfg['metadata']['requirements'])
            commands = [cfg['source']['command'], cfg['preview']['command']]
            commands += [v['command'] for v in cfg.get('actions', {}).values()]
            for cmd in commands:
                self.assertNotIn("'{}'", cmd)
                self.assertNotIn('split:\\t:1', cmd)
                if shutil.which('fish'):
                    result = subprocess.run(['fish', '--no-config', '--no-execute', '-c', cmd], capture_output=True)
                    self.assertEqual(result.returncode, 0, result.stderr)
        cfg = tomllib.loads((TV_ROOT / 'cable/git-log.toml').read_text())
        self.assertEqual(cfg['keybindings']['ctrl-c'], 'quit')


if __name__ == '__main__':
    unittest.main()
