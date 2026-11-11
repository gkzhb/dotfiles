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
            self.assertIn('--ansi', args)
            self.assertIn('--expect=enter,ctrl-r', args)
            self.assertNotIn('FZF_DEFAULT_OPTS', kwargs['env'])
            self.assertEqual(kwargs['input'].split(b'\t')[0], b'0')
            self.assertTrue(kwargs['input'].endswith(b'\0'))
            preview = next(a.split('=', 1)[1] for a in args if a.startswith('--preview='))
            result = subprocess.run([kwargs['env']['SHELL'], '-c', preview.replace('{1}', '0')], capture_output=True, text=True, check=True)
            self.assertEqual(result.stdout.strip(), 'FULL PATH')
            return subprocess.CompletedProcess(args, 0, b'enter\x000\twhatever\0')
        real_run = subprocess.run
        def dispatch(args, **kwargs):
            if args[0] == 'fzf':
                with patch.object(picker.subprocess, 'run', real_run):
                    return fzf(args, **kwargs)
            return real_run(args, **kwargs)
        with patch.dict(os.environ, {'FZF_DEFAULT_OPTS': '--multi'}), patch.object(picker.subprocess, 'run', side_effect=dispatch):
            self.assertEqual(picker.choose(records), ('switch', records[0]))

    def test_colored_rows_preserve_alignment_and_sanitize(self):
        record = {'fields': ['*', '会话\x1b\n', 'repo', 'main', '目录', 'dev', '1', 'current']}
        plain_header, plain_rows = picker.rows([record])
        header, rows = picker.rows([record], colored=True)
        import re
        strip = lambda s: re.sub(r'\x1b\[[0-9;]*m', '', s)
        self.assertEqual(strip(header), plain_header)
        self.assertEqual(strip(rows[0]), plain_rows[0])
        self.assertIn('\x1b[36mrepo', rows[0])
        self.assertIn('\x1b[35mmain', rows[0])
        self.assertIn('\x1b[34m目录', rows[0])
        self.assertIn('\x1b[33mdev', rows[0])
        self.assertEqual(picker.display_width('目录'), 4)
        self.assertEqual(picker.display_width('e\u0301'), 1)
        self.assertNotIn('\x1b', plain_rows[0])

    def test_no_color_and_kill_action_keep_exact_record(self):
        record = {'name': 'name', 'fields': [' ', 'name', 'repo', 'main', 'dir', 'dev', '1', 'detached'], 'preview': ''}
        with patch.dict(os.environ, {'NO_COLOR': '1'}), patch.object(picker.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, b'ctrl-r\x000\tignored\0')) as run:
            self.assertEqual(picker.choose([record]), ('kill', record))
        self.assertIn('--no-color', run.call_args.args[0])
        self.assertNotIn(b'\x1b', run.call_args.kwargs['input'])

    def test_malformed_selection_is_rejected(self):
        record = {'name': 's', 'fields': [' ', 's', 'r', 'b', 'd', 'b', '1', 'detached'], 'preview': ''}
        for output in (b'enter\x00-1\trow\0', b'enter\x0099\trow\0',
                       b'unknown\x000\trow\0', b'0\trow\0'):
            with self.subTest(output=output), patch.object(picker.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, output)):
                with self.assertRaises(picker.PickerError):
                    picker.choose([record])

    def test_kill_uses_exact_json_name_and_checks_twice(self):
        record = {'name': '-name \"; $(bad) @host\n', 'id': '12345678-1234-1234-1234-123456789abc'}
        with patch.object(picker, 'tuios_json', side_effect=[[record], [record], {'type': 'ok'}]) as api, patch.object(picker, 'confirm_kill', return_value=True):
            self.assertTrue(picker.kill_selected(record, 'source'))
        self.assertEqual(api.call_args_list[0].args, ('ls',))
        self.assertEqual(api.call_args_list[1].args, ('ls',))
        args = api.call_args_list[2].args
        self.assertEqual(args[:2], ('call', 'kill-session'))
        self.assertEqual(json.loads(args[2]), {'session': record['name']})

    def test_kill_confirmation_cancel_never_calls_kill(self):
        record = {'name': 'target', 'id': '12345678-1234-1234-1234-123456789abc'}
        with patch.object(picker, 'tuios_json', return_value=[record]) as api, patch.object(picker, 'confirm_kill', return_value=False):
            self.assertFalse(picker.kill_selected(record, 'source'))
        api.assert_called_once_with('ls')

    def test_current_session_missing_id_and_replacement_are_refused(self):
        record = {'name': 'target', 'id': '12345678-1234-1234-1234-123456789abc'}
        cases = [(record, [record], 'target'),
                 ({'name': 'target'}, [record], 'source'),
                 (record, [dict(record, id='87654321-1234-1234-1234-123456789abc')], 'source'),
                 (record, [dict(record, name='renamed')], 'source')]
        for selected, listing, source in cases:
            with self.subTest(selected=selected, listing=listing, source=source), patch.object(picker, 'tuios_json', return_value=listing) as api, patch.object(picker, 'confirm_kill') as confirm:
                with self.assertRaises(picker.PickerError):
                    picker.kill_selected(selected, source)
                confirm.assert_not_called()
                self.assertTrue(all(c.args == ('ls',) for c in api.call_args_list))

    def test_session_replaced_during_confirmation_is_not_killed(self):
        record = {'name': 'target', 'id': '12345678-1234-1234-1234-123456789abc'}
        replacement = dict(record, id='87654321-1234-1234-1234-123456789abc')
        with patch.object(picker, 'tuios_json', side_effect=[[record], [replacement]]) as api, patch.object(picker, 'confirm_kill', return_value=True):
            with self.assertRaises(picker.PickerError):
                picker.kill_selected(record, 'source')
        self.assertEqual(api.call_count, 2)

    def test_confirmation_requires_explicit_kill_selection(self):
        for code, output, confirmed in ((0, b'0\tCancel\0', False), (0, b'1\tKill\0', True), (130, b'', False)):
            with self.subTest(code=code, output=output), patch.object(picker.subprocess, 'run', return_value=subprocess.CompletedProcess([], code, output)) as run:
                self.assertEqual(picker.confirm_kill({'name': 'unsafe\n\x1b'}), confirmed)
                payload = run.call_args.kwargs['input']
                self.assertTrue(payload.startswith(b'0\tCancel'))
                self.assertNotIn(b'\x1b', payload)

    def test_kill_refreshes_and_never_switches(self):
        record = {'name': 'target'}
        with patch.object(picker.shutil, 'which', return_value='/bin/tool'), patch.object(picker, 'collect', side_effect=[[record], []]) as collect, patch.object(picker, 'choose', return_value=('kill', record)), patch.object(picker, 'kill_selected', return_value=True) as kill, patch.object(picker.subprocess, 'call') as switch:
            self.assertEqual(picker.main(['--inline', '--source', 'source']), 0)
        kill.assert_called_once_with(record, 'source')
        self.assertEqual(collect.call_count, 2)
        switch.assert_not_called()

    def test_kill_error_is_not_retried_or_switched(self):
        record = {'name': 'target', 'id': '12345678-1234-1234-1234-123456789abc'}
        with patch.object(picker, 'tuios_json', side_effect=[[record], [record], picker.PickerError('forbidden')]) as api, patch.object(picker, 'confirm_kill', return_value=True):
            with self.assertRaisesRegex(picker.PickerError, 'forbidden'):
                picker.kill_selected(record, 'source')
        self.assertEqual(api.call_count, 3)

    def test_cancel_does_not_switch(self):
        with patch.object(picker.shutil, 'which', return_value='/bin/tool'), patch.object(picker, 'collect', return_value=[{}]), patch.object(picker, 'choose', return_value=None), patch.object(picker.subprocess, 'call') as switch:
            self.assertEqual(picker.main(['--inline', '--source', 'source']), 0)
            switch.assert_not_called()

    def test_exact_session_argv_no_attach(self):
        target = '-target "with spaces"'
        with patch.object(picker.shutil, 'which', return_value='/bin/tool'), patch.object(picker, 'collect', return_value=[{}]), patch.object(picker, 'choose', return_value=('switch', {'name': target})), patch.object(picker.subprocess, 'call', return_value=0) as switch:
            self.assertEqual(picker.main(['--inline', '--source', 'source']), 0)
            switch.assert_called_once_with(['tuios', 'switch-session', '-s', 'source', '--', target])

    def test_selecting_current_session_does_not_switch(self):
        with patch.object(picker.shutil, 'which', return_value='/bin/tool'), patch.object(picker, 'collect', return_value=[{}]), patch.object(picker, 'choose', return_value=('switch', {'name': 'source'})), patch.object(picker.subprocess, 'call') as switch:
            self.assertEqual(picker.main(['--inline', '--source', 'source']), 0)
            switch.assert_not_called()

    def test_default_opens_popup_with_original_context(self):
        with patch.object(picker.shutil, 'which', return_value='/bin/tool'), patch.object(picker.subprocess, 'call', return_value=0) as popup:
            self.assertEqual(picker.main(['--source', 'source', '--active-pane', 'original']), 0)
            argv = popup.call_args.args[0]
            self.assertEqual(argv[:4], ['tuios', 'popup', '-s', 'source'])
            self.assertIn('--terminal-mode', argv)
            self.assertEqual(argv[-4:], ['--source', 'source', '--active-pane', 'original'])

    def test_popup_terminal_mode_routes_exact_session(self):
        source = '-source @literal'
        with patch.object(picker, 'tuios_json', side_effect=[[{'session': source}, {'session': 'other'}], {'routed': True}]) as api:
            picker.enter_popup_terminal_mode(source)
        self.assertEqual(api.call_args_list[0].args, ('list-clients',))
        args = api.call_args_list[1].args
        self.assertEqual(args[:2], ('call', 'run-command'))
        self.assertEqual(json.loads(args[2]), {'session': source, 'command': 'TerminalMode'})

    def test_popup_terminal_mode_refuses_ambiguous_client(self):
        for listing in ([], [{'session': 's'}, {'session': 's'}], {}):
            with self.subTest(listing=listing), patch.object(picker, 'tuios_json', return_value=listing) as api:
                with self.assertRaises(picker.PickerError):
                    picker.enter_popup_terminal_mode('s')
                api.assert_called_once_with('list-clients')

    def test_terminal_mode_runs_before_picker_only_when_explicit(self):
        events = []
        with patch.object(picker.shutil, 'which', return_value='/bin/tool'), patch.object(picker, 'enter_popup_terminal_mode', side_effect=lambda s: events.append(('mode', s))), patch.object(picker, 'collect', side_effect=lambda *a: events.append(('collect',)) or []):
            self.assertEqual(picker.main(['--inline', '--terminal-mode', '--source', 's']), 0)
        self.assertEqual(events, [('mode', 's'), ('collect',)])

    def test_plain_inline_and_list_do_not_change_terminal_mode(self):
        for argv in (['--inline'], ['--list']):
            with self.subTest(argv=argv), patch.object(picker.shutil, 'which', return_value='/bin/tool'), patch.object(picker, 'collect', return_value=[]), patch.object(picker, 'enter_popup_terminal_mode') as mode:
                self.assertEqual(picker.main(argv), 0)
                mode.assert_not_called()
        with self.assertRaises(picker.PickerError):
            picker.main(['--list', '--terminal-mode'])

    def test_daemon_failure_is_not_empty_list(self):
        with patch.object(picker.subprocess, 'run', return_value=subprocess.CompletedProcess([], 3, '[]', 'daemon stopped')):
            with self.assertRaisesRegex(picker.PickerError, 'daemon stopped'):
                picker.tuios_json('ls')


if __name__ == '__main__':
    unittest.main()
