"""Temporary Git + fake tuios/Television tests. Never touches a real session."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('worktree_session', ROOT / 'worktree-session.py')
helper = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(helper)


class WorktreeSessionTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name).resolve()
        self.repo = self.base / 'repo'
        self.repo.mkdir()
        self.git('init', '-q')
        self.git('-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
                 'commit', '--allow-empty', '-qm', 'init')
        self.target = self.base / "work tree'\nnext"
        self.git('worktree', 'add', '-q', '--detach', str(self.target))
        self.state = self.base / 'state.json'
        self.log = self.base / 'calls.jsonl'
        self.bin = self.base / 'bin'
        self.bin.mkdir()
        self.home = self.base / 'home'
        config = self.home / '.config'
        config.mkdir(parents=True)
        (config / 'tuios').symlink_to(ROOT, target_is_directory=True)
        (config / 'television').symlink_to(ROOT.parent / 'television', target_is_directory=True)
        self.executable('tuios', r'''import json,os,sys
from pathlib import Path
args=sys.argv[1:]
with open(os.environ['RECORD'], 'a') as stream: stream.write(json.dumps(args)+'\n')
state=json.loads(Path(os.environ['STATE']).read_text())
if args[:2]==['ls','--json']:
 print(state.get('raw',json.dumps(state.get('sessions',[]))))
 sys.exit(state.get('ls_status',0))
if args[:3]==['list-windows','--all','--json']:
 print(json.dumps(state.get('panes',{'panes':[]}))); sys.exit(0)
if args[:2]==['list-clients','--json']:
 print(json.dumps(state.get('clients',[{'client_id':'source-client','session':'source'}]))); sys.exit(0)
if state.get('fail')==args[0]:
 print('forbidden',file=sys.stderr); sys.exit(1)
if args[:1]==['new']:
 print(state.get('new_output', "Created detached session 'session-7'. Attach with 'tuios attach session-7'.")); sys.exit(0)
print('{}')
''')
        self.executable('tv', r'''import os,sys,json
with open(os.environ['RECORD'], 'a') as stream: stream.write(json.dumps(['tv',*sys.argv[1:]])+'\n')
print(os.environ.get('SELECTION',''))
sys.exit(int(os.environ.get('PICKER_STATUS','0')))
''')
        self.env = dict(os.environ, HOME=str(self.home),
                        PATH=str(self.bin) + os.pathsep + os.environ['PATH'],
                        STATE=str(self.state), RECORD=str(self.log))
        for key in list(self.env):
            if key.startswith('TUIOS_') or key.startswith('XDG_'):
                del self.env[key]
        self.set_state()

    def executable(self, name, source):
        executable = self.bin / name
        executable.write_text('#!' + shutil.which('python3') + '\n' + source)
        executable.chmod(0o755)

    def git(self, *args):
        return subprocess.run(['git', '-C', str(self.repo), *args], capture_output=True,
                              check=True).stdout

    def set_state(self, **state):
        self.state.write_text(json.dumps(state))

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []

    def invoke(self, switch=True, path=None):
        return subprocess.run([shutil.which('python3'), str(ROOT / 'worktree-session.py'),
                               '--switch' if switch else '--attach', '--',
                               str(path or self.target)], env=self.env, capture_output=True)

    def row(self, name='renamed', path=None, **extra):
        return dict(name=name, worktree={'path': str(path or self.target)}, **extra)

    def switch_params(self):
        return json.loads(self.calls()[-1][2])

    def test_reuses_metadata_even_when_renamed(self):
        self.set_state(sessions=[self.row("build:api ' $(touch NO)")])
        self.assertEqual(self.invoke().returncode, 0)
        self.assertEqual(self.switch_params(), {'name': "build:api ' $(touch NO)"})
        self.assertFalse(any(c[0] in ('new', 'list-windows') for c in self.calls()))

    def test_missing_switch_creates_with_exact_path(self):
        self.assertEqual(self.invoke().returncode, 0)
        params = self.switch_params()
        self.assertEqual(params, {'name': 'session-7', 'client': 'source-client'})
        self.assertEqual(self.calls()[-2], ['new', '--detach', '--cwd', str(self.target)])

    def test_missing_external_creates_then_attaches(self):
        self.assertEqual(self.invoke(switch=False).returncode, 0)
        self.assertEqual(self.calls()[1], ['new', '--detach', '--cwd', str(self.target)])
        self.assertEqual(self.calls()[2], ['attach', '--', 'local:session-7'])

    def test_external_reuse_colon_name_stays_local(self):
        self.set_state(sessions=[self.row('host:custom')])
        self.assertEqual(self.invoke(switch=False).returncode, 0)
        self.assertEqual(self.calls()[-1], ['attach', '--', 'local:host:custom'])
        self.assertFalse(any(c[0] == 'new' for c in self.calls()))

    def test_symlink_path_reuses(self):
        alias = self.base / 'alias'
        alias.symlink_to(self.target, target_is_directory=True)
        self.set_state(sessions=[self.row(path=alias)])
        self.assertEqual(self.invoke(path=alias).returncode, 0)
        self.assertEqual(self.switch_params(), {'name': 'renamed'})

    def test_main_checkout_is_selectable(self):
        self.set_state(sessions=[self.row(path=self.repo)])
        self.assertEqual(self.invoke(path=self.repo).returncode, 0)
        self.assertEqual(self.switch_params(), {'name': 'renamed'})

    def test_fallback_first_pane_in_subdirectory(self):
        subdir = self.target / 'sub'
        subdir.mkdir()
        self.set_state(sessions=[dict(name='old', windows=[{'id': 'one'}])],
                       panes={'panes': [dict(session='old', window_id='one', cwd=str(subdir))]})
        self.assertEqual(self.invoke().returncode, 0)
        self.assertEqual(self.switch_params(), {'name': 'old'})

    def test_other_metadata_and_later_remote_popup_panes_do_not_match(self):
        cases = [
            ([self.row(path=self.repo)], dict(session='renamed', window_id='one', cwd=str(self.target))),
            ([dict(name='old', windows=[{'id': 'one'}, {'id': 'two'}])],
             dict(session='old', window_id='two', cwd=str(self.target))),
            ([dict(name='old', windows=[{'id': 'one'}])],
             dict(session='old', window_id='one', cwd=str(self.target), host='remote')),
            ([dict(name='old', windows=[{'id': 'one'}])],
             dict(session='old', window_id='one', cwd=str(self.target), popup=True)),
        ]
        for sessions, pane in cases:
            with self.subTest(pane=pane):
                self.set_state(sessions=sessions, panes={'panes': [pane]})
                self.assertEqual(self.invoke().returncode, 0)
                self.assertEqual(self.switch_params()['name'], 'session-7')
                self.assertEqual(self.calls()[-2], ['new', '--detach', '--cwd', str(self.target)])

    def test_duplicate_path_prefers_current_then_most_recent(self):
        self.set_state(sessions=[self.row('older', last_active=1), self.row('recent', last_active=10)])
        self.assertEqual(self.invoke().returncode, 0)
        self.assertEqual(self.switch_params(), {'name': 'recent'})
        self.env['TUIOS_SESSION'] = 'older'
        self.assertEqual(self.invoke().returncode, 0)
        self.assertEqual(self.switch_params(), {'name': 'older'})

    def test_same_basename_different_path_does_not_reuse(self):
        other = self.base / 'other' / self.target.name
        other.parent.mkdir()
        self.git('worktree', 'add', '-q', '--detach', str(other))
        self.set_state(sessions=[self.row(name='session-1', path=other)])
        self.assertEqual(self.invoke().returncode, 0)
        self.assertEqual(self.switch_params()['name'], 'session-7')
        self.assertEqual(self.calls()[-2], ['new', '--detach', '--cwd', str(self.target)])

    def test_saved_daemon_is_refused_without_mutations(self):
        self.set_state(sessions=[dict(name='saved', saved=True)], ls_status=3)
        result = self.invoke()
        self.assertEqual(result.returncode, 1)
        self.assertIn(b'restore', result.stderr)
        self.assertEqual(self.calls(), [['ls', '--json']])

    def test_no_saved_daemon_can_create(self):
        self.set_state(sessions=[], ls_status=3)
        self.assertEqual(self.invoke(switch=False).returncode, 0)
        self.assertEqual(self.calls()[1][0], 'new')

    def test_invalid_listing_or_list_failure_is_not_empty(self):
        for state in ({'raw': 'not-json'}, {'raw': '{}'}, {'sessions': [None]}, {'ls_status': 1}):
            with self.subTest(state=state):
                self.set_state(**state)
                self.assertEqual(self.invoke().returncode, 1)
        self.assertTrue(all(call == ['ls', '--json'] for call in self.calls()))

    def test_malformed_panes_fail_closed(self):
        self.set_state(sessions=[dict(name='old', windows=[{'id': 'one'}])], panes={})
        self.assertEqual(self.invoke().returncode, 1)
        self.assertEqual(len(self.calls()), 2)

    def test_partial_pane_listing_error_prevents_creation(self):
        self.set_state(sessions=[dict(name='old', windows=[{'id': 'one'}])],
                       panes={'panes': [], 'errors': [{'session': 'old', 'error': 'forbidden'}]})
        self.assertEqual(self.invoke().returncode, 1)
        self.assertEqual([call[0] for call in self.calls()], ['ls', 'list-windows'])

    def test_invalid_directory_or_subdirectory_never_calls_tuios(self):
        subdir = self.target / 'sub'
        subdir.mkdir()
        for path in (self.base / 'missing', subdir, self.base):
            with self.subTest(path=path):
                self.assertEqual(self.invoke(path=path).returncode, 1)
        self.assertEqual(self.calls(), [])

    def test_switch_failure_no_retry(self):
        self.set_state(sessions=[self.row()], fail='call')
        self.assertEqual(self.invoke().returncode, 1)
        self.assertEqual([call[0] for call in self.calls()], ['ls', 'call'])

    def test_creation_failure_does_not_attach(self):
        self.set_state(fail='new')
        self.assertEqual(self.invoke(switch=False).returncode, 1)
        self.assertEqual([call[0] for call in self.calls()], ['ls', 'new'])

    def test_ambiguous_source_clients_do_not_create(self):
        self.set_state(clients=[{'client_id': 'one', 'session': 'source'},
                                {'client_id': 'two', 'session': 'source'}])
        self.env['TUIOS_SESSION'] = 'source'
        self.assertEqual(self.invoke().returncode, 1)
        self.assertEqual([call[0] for call in self.calls()], ['ls', 'list-clients'])

    def test_unknown_creation_output_does_not_attach_or_retry(self):
        self.set_state(new_output='unexpected output')
        result = self.invoke(switch=False)
        self.assertEqual(result.returncode, 1)
        self.assertIn(b'inspect tuios ls', result.stderr)
        self.assertEqual([call[0] for call in self.calls()], ['ls', 'new'])

    def test_timeout_is_error_not_retry(self):
        with patch.object(helper.subprocess, 'run', side_effect=subprocess.TimeoutExpired('tuios', 15)) as run:
            with self.assertRaisesRegex(helper.Error, 'inspect session state'):
                helper.run('tuios', 'ls', '--json')
        self.assertEqual(run.call_count, 1)

    def fish(self, *args, selection=None, picker_status=0):
        if not shutil.which('fish'):
            self.skipTest('fish not installed')
        if selection is None:
            selection = json.dumps(str(self.target), ensure_ascii=True).encode().hex()
        env = dict(self.env, SELECTION=selection, PICKER_STATUS=str(picker_status),
                   XDG_CONFIG_HOME=str(self.home / '.config'))
        result = subprocess.run(['fish', '--no-config', '-c',
                                 'source "$argv[1]"; tvn $argv[2..]; set -l result $status; '
                                 'printf "%s\\0" "$PWD"; exit $result',
                                 str(ROOT.parent / 'fish/functions/tvn.fish'), *args],
                                cwd=self.repo, env=env, capture_output=True)
        self.assertTrue(result.stdout.endswith(os.fsencode(self.repo) + b'\0'))
        return result

    def test_fish_picker_token_to_switch_without_changing_cwd(self):
        self.env.update(TUIOS_ENV='1', TUIOS_SESSION='source')
        result = self.fish()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls()[0], ['tv', 'git-worktrees', str(self.repo), '--no-remote'])
        self.assertEqual(self.calls()[-2], ['new', '--detach', '--cwd', str(self.target)])
        self.assertEqual(self.switch_params()['name'], 'session-7')

    def test_fish_explicit_repo_and_external_attach(self):
        result = self.fish(str(self.target))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls()[0], ['tv', 'git-worktrees', str(self.target), '--no-remote'])
        self.assertEqual(self.calls()[-1][0], 'attach')

    def test_fish_cancel_or_empty_does_not_call_tuios(self):
        for selection, status in (('', 130), ('', 0)):
            result = self.fish(selection=selection, picker_status=status)
            self.assertEqual(result.returncode, status, result.stderr)
        self.assertTrue(all(call[0] == 'tv' for call in self.calls()))

    def test_fish_invalid_or_multiple_tokens_does_not_call_tuios(self):
        for selection in ('invalid', 'abcd\nef01'):
            self.assertEqual(self.fish(selection=selection).returncode, 1)
        self.assertTrue(all(call[0] == 'tv' for call in self.calls()))

    def test_fish_help_arguments_and_nonrepo(self):
        self.assertEqual(self.fish('--help').returncode, 0)
        self.assertEqual(self.fish('one', 'two').returncode, 2)
        self.assertEqual(self.fish(str(self.base)).returncode, 1)
        self.assertEqual(self.calls(), [])


if __name__ == '__main__':
    unittest.main()
