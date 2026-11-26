"""Isolated session fixtures and temporary Git repos; never opens real VS Code."""
import contextlib
import importlib.util
import io
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import tomllib
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('open_vscode', ROOT / 'open-vscode.py')
helper = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(helper)


class OpenVscodeTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.base = Path(tmp.name).resolve()
        self.repo = self.base / "project ' $(touch NO)"
        self.repo.mkdir()
        self.subdir = self.repo / 'src'
        self.subdir.mkdir()
        subprocess.run(['git', 'init', '-q', str(self.repo)], check=True, capture_output=True)
        self.source = {'name': 'current', 'windows': [{'id': 'first'}, {'id': 'focused'}]}
        self.panes = [{'session': 'current', 'window_id': 'first', 'cwd': str(self.subdir)},
                      {'session': 'current', 'window_id': 'focused', 'cwd': str(self.base)}]
        mock = patch.object(helper, 'tuios_json', side_effect=self.listing)
        self.api = mock.start()
        self.addCleanup(mock.stop)

    def listing(self, *args):
        if args == ('ls',):
            return [dict(name='other', worktree={'path': str(self.base)}), self.source]
        self.assertEqual(args, ('list-windows', '--all'))
        return {'panes': self.panes}

    def invoke(self, *args):
        with patch.object(sys, 'argv', ['open-vscode.py', *args]), \
                patch.dict(os.environ, {'TUIOS_SESSION': 'current'}), \
                contextlib.redirect_stdout(io.StringIO()) as out, \
                contextlib.redirect_stderr(io.StringIO()) as err:
            status = helper.main()
        return status, out.getvalue(), err.getvalue()

    def test_metadata_wins_over_focused_pane_and_caller_cwd(self):
        self.source['worktree'] = {'path': str(self.repo), 'repo_root': str(self.base), 'main': True}
        self.assertEqual(helper.project_root('current'), str(self.repo))
        self.assertEqual(self.api.call_count, 1)

    def test_real_linked_worktree_opens_branch_checkout_not_main(self):
        subprocess.run(['git', '-C', str(self.repo), '-c', 'user.name=Test',
                        '-c', 'user.email=test@example.invalid', 'commit', '--allow-empty', '-qm', 'init'],
                       check=True, capture_output=True)
        target = self.base / 'work tree\nnext'
        subprocess.run(['git', '-C', str(self.repo), 'worktree', 'add', '-q', '--detach', str(target)],
                       check=True, capture_output=True)
        self.source['worktree'] = {'path': str(target), 'repo_root': str(self.repo)}
        self.assertEqual(helper.project_root('current'), str(target))
        del self.source['worktree']
        subdir = target / 'src'
        subdir.mkdir()
        self.panes[0]['cwd'] = str(subdir)
        self.assertEqual(helper.project_root('current'), str(target))

    def test_fallback_uses_first_window_git_root_not_focused_window(self):
        self.assertEqual(helper.project_root('current'), str(self.repo))

    def test_fallback_ignores_caller_git_overrides(self):
        with patch.dict(os.environ, {'GIT_DIR': '/missing/git', 'GIT_WORK_TREE': str(self.base)}):
            self.assertEqual(helper.project_root('current'), str(self.repo))

    def test_non_git_project_uses_first_pane_directory(self):
        self.panes[0]['cwd'] = str(self.base)
        self.assertEqual(helper.project_root('current'), str(self.base))

    def test_symlink_is_resolved(self):
        alias = self.base / 'alias'
        alias.symlink_to(self.repo, target_is_directory=True)
        self.source['worktree'] = {'path': str(alias)}
        self.assertEqual(helper.project_root('current'), str(self.repo))

    def test_missing_or_malformed_metadata_does_not_fallback(self):
        for metadata in ({'path': str(self.repo), 'gone': True}, {'path': '/missing/project'},
                         {'path': 'relative'}, {'path': 'bad\0path'}, {}, 'invalid'):
            with self.subTest(metadata=metadata):
                self.source['worktree'] = metadata
                self.api.reset_mock()
                with self.assertRaises(helper.Error):
                    helper.project_root('current')
                self.assertEqual(self.api.call_count, 1)

    def test_missing_or_saved_session_is_rejected(self):
        for name in (None, 'missing'):
            with self.assertRaises(helper.Error):
                helper.project_root(name)
        self.source['saved'] = True
        with self.assertRaises(helper.Error):
            helper.project_root('current')

    def test_no_project_window_does_not_use_another_pane(self):
        for windows in ([], None, ['bad'], [{'id': 'gone'}]):
            with self.subTest(windows=windows):
                self.source['windows'] = windows
                with self.assertRaises(helper.Error):
                    helper.project_root('current')

    def test_remote_popup_or_untrusted_first_pane_is_rejected(self):
        for extra in ({'host': 'remote'}, {'popup': True}, {'untrusted': True}):
            with self.subTest(extra=extra):
                original = dict(self.panes[0])
                self.panes[0].update(extra)
                with self.assertRaises(helper.Error):
                    helper.project_root('current')
                self.panes[0] = original

    def test_missing_directory_is_rejected(self):
        self.panes[0]['cwd'] = '/missing/project'
        with self.assertRaises(helper.Error):
            helper.project_root('current')

    def test_open_passes_exact_path_as_argv(self):
        self.source['worktree'] = {'path': str(self.repo)}
        with patch.object(helper, 'run') as command:
            status, _, error = self.invoke()
        self.assertEqual((status, error), (0, ''))
        command.assert_called_once_with('code', '--', str(self.repo))
        self.assertFalse((self.base / 'NO').exists())

    def test_print_root_never_launches_code(self):
        self.source['worktree'] = {'path': str(self.repo)}
        with patch.object(helper, 'run') as command:
            status, output, error = self.invoke('--print-root')
        self.assertEqual((status, output, error), (0, str(self.repo) + '\n', ''))
        command.assert_not_called()

    def test_explicit_session_overrides_environment(self):
        self.source['worktree'] = {'path': str(self.repo)}
        status, output, error = self.invoke('--session', 'other', '--print-root')
        self.assertEqual((status, output, error), (0, str(self.base) + '\n', ''))

    def test_failure_never_launches_code(self):
        self.source['worktree'] = {'path': '/missing/project'}
        with patch.object(helper, 'run') as command:
            status, _, error = self.invoke()
        self.assertEqual(status, 1)
        self.assertIn('missing', error)
        command.assert_not_called()

    def test_code_missing_or_failure_reports_error(self):
        self.source['worktree'] = {'path': str(self.repo)}
        for error in (FileNotFoundError('code not found'), helper.Error('code failed')):
            with patch.object(helper, 'run', side_effect=error):
                status, _, message = self.invoke()
            self.assertEqual(status, 1)
            self.assertIn(str(error), message)

    def test_binding_preserves_lowercase_sidebar_key(self):
        config = tomllib.loads((ROOT / 'config.toml').read_text())
        keys = config['keybindings']
        binding = next(row for row in keys['command'] if row['key'] == 'prefix+E')
        self.assertEqual(binding['type'], 'shell')
        self.assertEqual(binding['command'], 'python3 ~/.config/tuios/open-vscode.py')
        self.assertEqual(keys['leader_key'], 'ctrl+f')
        self.assertEqual(keys['prefix_mode']['prefix_explore'], ['e'])
        self.assertEqual(keys['prefix_mode']['edit_scrollback'], [])


class CommandTests(unittest.TestCase):
    def test_invalid_json_and_partial_errors_fail_closed(self):
        for raw in (b'not JSON', b'{"errors":["forbidden"]}', b'{"success":false}'):
            with patch.object(helper, 'run', return_value=subprocess.CompletedProcess([], 0, raw)):
                with self.assertRaises(helper.Error):
                    helper.tuios_json('ls')

    def test_permission_and_timeout_errors_are_not_retried(self):
        outcomes = [subprocess.CompletedProcess([], 1, b'', b'forbidden'),
                    subprocess.TimeoutExpired('tuios', 15)]
        for outcome in outcomes:
            with patch.object(helper.subprocess, 'run') as command:
                if isinstance(outcome, Exception):
                    command.side_effect = outcome
                else:
                    command.return_value = outcome
                with self.assertRaises(helper.Error):
                    helper.run('tuios', 'ls', '--json')
                self.assertEqual(command.call_count, 1)


if __name__ == '__main__':
    unittest.main()
