import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / 'session-switcher.py'
spec = importlib.util.spec_from_file_location('picker', SCRIPT)
picker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(picker)


class PickerTests(unittest.TestCase):
    def test_git_branch_detached_unborn_and_non_repo(self):
        with tempfile.TemporaryDirectory() as tmp:
            def git(*args):
                return subprocess.run(['git', '-C', tmp, *args], check=True, capture_output=True, text=True).stdout.strip()
            self.assertEqual(picker.git_info(tmp), (None, 'not a repository'))
            git('init', '-b', 'feature/test')
            self.assertEqual(picker.git_info(tmp)[0]['ref'], 'feature/test')
            git('-c', 'user.name=Test', '-c', 'user.email=test@example.com', 'commit', '--allow-empty', '-m', 'test')
            commit = git('rev-parse', '--short=12', 'HEAD')
            git('checkout', '--detach')
            with patch.dict(os.environ, {'GIT_DIR': '/invalid', 'GIT_WORK_TREE': '/invalid'}):
                self.assertEqual(picker.git_info(tmp)[0]['ref'], commit + ' (detached)')

    def test_missing_directory(self):
        self.assertEqual(picker.git_info('/nonexistent/picker-test'), (None, 'unavailable'))

    def test_focused_directory_wins_and_popup_is_ignored(self):
        sessions = [{'name': 'source', 'branch': 'stale', 'last_active': 1}, {'name': 'other', 'last_active': 2}]
        panes = [
            {'session': 'source', 'window_id': 'original', 'cwd': '/repo', 'workspace': 2},
            {'session': 'source', 'window_id': 'popup', 'cwd': '/wrong', 'focused': True},
            {'session': 'other', 'window_id': 'other-pane', 'cwd': '/other', 'focused': True},
        ]
        def repo(cwd):
            return {'root': cwd, 'ref': 'live-branch', 'commit': 'abcdef'}, ''
        with patch.object(picker, 'tuios_json', side_effect=[sessions, {'panes': panes}]), patch.object(picker, 'git_info', side_effect=repo), patch.dict(os.environ, {'TUIOS_WINDOW_ID': 'popup'}):
            records = picker.collect('source', 'original')
        self.assertEqual([r['name'] for r in records], ['other', 'source'])
        self.assertEqual(records[1]['fields'][2:7], ['repo', 'live-branch', 'repo', 'live-branch', '1'])
        self.assertNotIn('/wrong', records[1]['preview'])
        self.assertIn('/repo', records[1]['preview'])

    def test_subdirectory_displays_git_repository_name(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / 'my-project'
            cwd = root / 'src' / 'components'
            cwd.mkdir(parents=True)
            subprocess.run(['git', '-C', str(root), 'init', '-b', 'main'],
                           check=True, capture_output=True)
            sessions = [{'name': 's'}]
            panes = {'panes': [{'session': 's', 'cwd': str(cwd), 'focused': True}]}
            with patch.object(picker, 'tuios_json', side_effect=[sessions, panes]):
                records = picker.collect()
        self.assertEqual(records[0]['fields'][2:6], ['my-project', 'main', 'components', 'main'])
        header, display = picker.rows(records)
        self.assertIn('GIT REPOSITORY', header)
        self.assertIn('my-project', display[0])

    def test_non_repo_does_not_use_stale_branch(self):
        sessions = [{'name': 's', 'branch': 'stale'}]
        panes = {'panes': [{'session': 's', 'cwd': '/plain', 'focused': True}]}
        with patch.object(picker, 'tuios_json', side_effect=[sessions, panes]), patch.object(picker, 'git_info', return_value=(None, 'not a repository')):
            self.assertEqual(picker.collect()[0]['fields'][2:6], ['—', '—', 'plain', '—'])

    def test_missing_cwd_uses_explicit_cached_metadata(self):
        sessions = [{'name': 's', 'dir': 'repo', 'branch': 'cached-branch'}]
        with patch.object(picker, 'tuios_json', side_effect=[sessions, {'panes': []}]), patch.object(picker, 'git_info', return_value=(None, 'unavailable')):
            self.assertEqual(picker.collect()[0]['fields'][2:6], ['—', 'cached-branch (cached)', '—', '—'])

    def test_worktree_metadata_wins_over_live_pane(self):
        for extra in ({'main': True}, {'managed': True}, {'gone': True}, {}):
            with self.subTest(extra=extra):
                worktree = dict(repo='canonical-project', branch='group-branch',
                                path='/worktrees/task', repo_root='/repos/project', **extra)
                sessions = [{'name': 's', 'branch': 'daemon-branch', 'worktree': worktree}]
                panes = {'panes': [{'session': 's', 'cwd': '/other/src', 'focused': True}]}
                repo = {'root': '/other', 'ref': 'pane-branch', 'commit': 'abcdef'}
                with patch.object(picker, 'tuios_json', side_effect=[sessions, panes]), patch.object(picker, 'git_info', return_value=(repo, '')):
                    record = picker.collect()[0]
                self.assertEqual(record['fields'][2:6],
                                 ['canonical-project', 'group-branch', 'src', 'pane-branch'])
                self.assertIn('Project source: tuios worktree metadata', record['preview'])
                self.assertIn('Project directory: /worktrees/task', record['preview'])
                self.assertIn('Repository root: /repos/project', record['preview'])
                self.assertIn('Pane directory: /other/src', record['preview'])
                self.assertIn('Pane repository: /other', record['preview'])
                self.assertIn(f'Worktree directory gone: {bool(extra.get("gone"))}', record['preview'])

    def test_focus_changes_only_pane_context_when_grouped(self):
        session = {'name': 's', 'worktree': {'repo': 'project', 'branch': 'group'}}
        for focused in ('a', 'b'):
            with self.subTest(focused=focused):
                panes = [{'session': 's', 'window_id': name, 'cwd': '/' + name,
                          'focused': name == focused} for name in ('a', 'b')]
                def repo(cwd):
                    return {'root': cwd, 'ref': 'branch-' + cwd[1:], 'commit': ''}, ''
                with patch.dict(os.environ, {'TUIOS_WINDOW_ID': ''}), patch.object(picker, 'tuios_json', side_effect=[[session], {'panes': panes}]), patch.object(picker, 'git_info', side_effect=repo):
                    fields = picker.collect()[0]['fields']
                self.assertEqual(fields[2:4], ['project', 'group'])
                self.assertEqual(fields[4:6], [focused, 'branch-' + focused])

    def test_group_metadata_does_not_fabricate_missing_pane_context(self):
        session = {'name': 's', 'worktree': {'repo': 'project', 'branch': 'main',
                                           'path': '/project'}}
        with patch.object(picker, 'tuios_json', side_effect=[[session], {'panes': []}]), patch.object(picker, 'git_info', return_value=(None, 'unavailable')) as git:
            record = picker.collect()[0]
        self.assertEqual(record['fields'][2:6], ['project', 'main', '—', '—'])
        self.assertIn('Pane directory: unknown', record['preview'])
        git.assert_called_once_with('')

    def test_partial_worktree_metadata_does_not_mix_with_pane(self):
        for worktree, expected in (({'repo': 'group'}, ['group', '—']),
                                   ({'branch': 'group-branch'}, ['—', 'group-branch'])):
            with self.subTest(worktree=worktree):
                session = {'name': 's', 'worktree': worktree}
                panes = {'panes': [{'session': 's', 'cwd': '/other', 'focused': True}]}
                repo = {'root': '/other', 'ref': 'pane-branch', 'commit': ''}
                with patch.object(picker, 'tuios_json', side_effect=[[session], panes]), patch.object(picker, 'git_info', return_value=(repo, '')):
                    fields = picker.collect()[0]['fields']
                self.assertEqual(fields[2:4], expected)
                self.assertEqual(fields[4:6], ['other', 'pane-branch'])

    def test_focused_pane_without_cwd_is_not_replaced_by_another_pane(self):
        session = {'name': 's', 'worktree': {'repo': 'project', 'branch': 'main'}}
        panes = {'panes': [{'session': 's', 'window_id': 'focused', 'focused': True},
                           {'session': 's', 'window_id': 'other', 'cwd': '/other'}]}
        with patch.dict(os.environ, {'TUIOS_WINDOW_ID': ''}), patch.object(picker, 'tuios_json', side_effect=[[session], panes]), patch.object(picker, 'git_info', return_value=(None, 'unavailable')):
            record = picker.collect()[0]
        self.assertEqual(record['fields'][4:6], ['—', '—'])
        self.assertIn('Selected pane: focused', record['preview'])

    def test_group_metadata_is_sanitized_for_display(self):
        session = {'name': 's', 'worktree': {'repo': 'repo\t\x1b', 'branch': 'branch\n\u202e'}}
        with patch.object(picker, 'tuios_json', side_effect=[[session], {'panes': []}]):
            record = picker.collect()[0]
        self.assertEqual(record['fields'][2:4], ['repo  ', 'branch  '])
        self.assertNotIn('\x1b', record['preview'])
        self.assertNotIn('\u202e', record['preview'])

    def test_sanitizes_display_but_preserves_exact_name(self):
        name = 'a\t";echo unsafe\n\x1b[31m\u202e'
        with patch.object(picker, 'tuios_json', side_effect=[[{'name': name}], {'panes': []}]):
            record = picker.collect()[0]
        self.assertEqual(record['name'], name)
        self.assertNotIn('\t', record['fields'][1])
        self.assertNotIn('\x1b', record['preview'])
        self.assertNotIn('\u202e', record['preview'])

    def test_empty_sessions_no_second_call(self):
        with patch.object(picker, 'tuios_json', return_value=[]) as read:
            self.assertEqual(picker.collect(), [])
            self.assertEqual(read.call_count, 1)

    def test_invalid_pane_response(self):
        with patch.object(picker, 'tuios_json', side_effect=[[{'name': 's'}], {}]):
            with self.assertRaises(picker.PickerError):
                picker.collect()

    def test_fzf_contract_and_safe_preview(self):
        records = [{'name': '-name with spaces', 'fields': [' ', 'name', 'repo', 'main', 'dir', 'main', '1', 'detached'], 'preview': 'FULL PATH'}]
        def fzf(args, **kwargs):
            self.assertIn('--read0', args)
            self.assertNotIn('FZF_DEFAULT_OPTS', kwargs['env'])
            self.assertEqual(kwargs['input'].split(b'\t')[0], b'0')
            self.assertTrue(kwargs['input'].endswith(b'\0'))
            preview = next(a.split('=', 1)[1] for a in args if a.startswith('--preview='))
            result = subprocess.run([kwargs['env']['SHELL'], '-c', preview.replace('{1}', '0')], capture_output=True, text=True, check=True)
            self.assertEqual(result.stdout.strip(), 'FULL PATH')
            return subprocess.CompletedProcess(args, 0, b'0\twhatever\0')
        real_run = subprocess.run
        def dispatch(args, **kwargs):
            if args[0] == 'fzf':
                with patch.object(picker.subprocess, 'run', real_run):
                    return fzf(args, **kwargs)
            return real_run(args, **kwargs)
        with patch.dict(os.environ, {'FZF_DEFAULT_OPTS': '--multi'}), patch.object(picker.subprocess, 'run', side_effect=dispatch):
            self.assertEqual(picker.choose(records), records[0]['name'])

    def test_cancel_does_not_switch(self):
        with patch.object(picker.shutil, 'which', return_value='/bin/tool'), patch.object(picker, 'collect', return_value=[{}]), patch.object(picker, 'choose', return_value=None), patch.object(picker.subprocess, 'call') as switch:
            self.assertEqual(picker.main(['--inline', '--source', 'source']), 0)
            switch.assert_not_called()

    def test_exact_session_argv_no_attach(self):
        target = '-target "with spaces"'
        with patch.object(picker.shutil, 'which', return_value='/bin/tool'), patch.object(picker, 'collect', return_value=[{}]), patch.object(picker, 'choose', return_value=target), patch.object(picker.subprocess, 'call', return_value=0) as switch:
            self.assertEqual(picker.main(['--inline', '--source', 'source']), 0)
            switch.assert_called_once_with(['tuios', 'switch-session', '-s', 'source', '--', target])

    def test_selecting_current_session_does_not_switch(self):
        with patch.object(picker.shutil, 'which', return_value='/bin/tool'), patch.object(picker, 'collect', return_value=[{}]), patch.object(picker, 'choose', return_value='source'), patch.object(picker.subprocess, 'call') as switch:
            self.assertEqual(picker.main(['--inline', '--source', 'source']), 0)
            switch.assert_not_called()

    def test_default_opens_popup_with_original_context(self):
        with patch.object(picker.shutil, 'which', return_value='/bin/tool'), patch.object(picker.subprocess, 'call', return_value=0) as popup:
            self.assertEqual(picker.main(['--source', 'source', '--active-pane', 'original']), 0)
            argv = popup.call_args.args[0]
            self.assertEqual(argv[:4], ['tuios', 'popup', '-s', 'source'])
            self.assertEqual(argv[-4:], ['--source', 'source', '--active-pane', 'original'])

    def test_daemon_failure_is_not_empty_list(self):
        with patch.object(picker.subprocess, 'run', return_value=subprocess.CompletedProcess([], 3, '[]', 'daemon stopped')):
            with self.assertRaisesRegex(picker.PickerError, 'daemon stopped'):
                picker.tuios_json('ls')


if __name__ == '__main__':
    unittest.main()
