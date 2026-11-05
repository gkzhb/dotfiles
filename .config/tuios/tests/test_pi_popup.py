import json
import os
import pathlib
import subprocess
import tempfile
import uuid

SCRIPT = pathlib.Path(__file__).resolve().parents[1] / 'pi-popup.fish'
# Optional old implementation for red/green regression verification.
SCRIPT = pathlib.Path(os.environ.get('PI_POPUP_TEST_SCRIPT', str(SCRIPT)))
SERVER = 'pip-' + uuid.uuid4().hex[:8]
ENV = dict(os.environ, TUIOS_SERVER=SERVER)
# Use a separate daemon, never the user's sessions or displayed client.
ENV.pop('TUIOS_SOCKET', None)

def run(*args, check=True, env=ENV):
    return subprocess.run(args, env=env, text=True, capture_output=True, check=check, timeout=15)

def tuios(*args, **kw):
    return run('tuios', '--server', SERVER, *args, **kw)

def helper(*args, **extra):
    env = dict(ENV, PI_POPUP_SESSION='helper-under-test', PI_POPUP_BIN='/bin/sleep')
    env.update(extra.pop('vars', {}))
    return run('fish', str(SCRIPT), *args, env=env, **extra)

try:
    tuios('new', '--detach', 'bootstrap')
    a = helper('--ensure-only', '--', '300').stdout.strip()
    assert a, 'no id'
    first = json.loads(tuios('list-windows', '-s', 'helper-under-test', '--json').stdout)
    assert len(first['windows']) == 1, first
    pane = first['windows'][0]
    assert pane['window_id'] == a and pane['display_name'] == 'pi', pane
    b = helper('--ensure-only', vars={'PI_POPUP_BIN': '/does/not/exist'}).stdout.strip()
    assert a == b, (a, b)
    print('PASS: lazy creation, one window, reuse without requiring Pi executable')
    tuios('close-window', '-s', 'helper-under-test', a)
    c = helper('--ensure-only', '--', '300').stdout.strip()
    assert c and a != c
    print('PASS: new process after dedicated window closes')
    # Real bug: a detached session retains an exited pane. Its last screen and
    # display_name look normal, but pane-view immediately ends with exit 0.
    exited = helper('--ensure-only', vars={'PI_POPUP_SESSION': 'exited-regression', 'PI_POPUP_BIN': '/usr/bin/true'}).stdout.strip()
    tuios('wait-for', 'window-exit', '-s', 'exited-regression', '-w', exited, '--timeout', '5000')
    retained = json.loads(tuios('list-windows', '-s', 'exited-regression', '--json').stdout)['windows']
    assert any(w['window_id'] == exited for w in retained), 'fixture must retain exited window'
    replacement = helper('--ensure-only', '--', '300', vars={'PI_POPUP_SESSION': 'exited-regression'}).stdout.strip()
    assert replacement != exited, 'BUG: reused exited pane; popup will immediately close'
    alive = tuios('call', 'wait-for', json.dumps({'session': 'exited-regression', 'window': replacement, 'condition': 'window-exit', 'timeout': 1}), check=False)
    assert json.loads(alive.stdout)['error']['code'] == 'timeout', alive
    print('PASS: retained exited pane replaced with a live process')
    bad = helper('--ensure-only', vars={'PI_POPUP_SESSION': 'bad-executable', 'PI_POPUP_BIN': '/missing/pi'}, check=False)
    assert bad.returncode == 127 and 'Missing Pi' in bad.stderr, bad
    names = [s['name'] for s in json.loads(tuios('ls', '--json').stdout)]
    assert 'bad-executable' not in names
    print('PASS: missing executable fails without creating session')
    bad = helper('--ensure-only', vars={'PI_POPUP_SESSION': 'bad-cwd', 'PI_POPUP_CWD': '/missing/cwd'}, check=False)
    assert bad.returncode == 2 and 'directory' in bad.stderr, bad
    print('PASS: invalid cwd fails')
    # Hold the init lock with a mock ls call; second initializer must not enter.
    with tempfile.TemporaryDirectory(prefix='pi-popup-mock-') as tmp:
        mock = pathlib.Path(tmp, 'tuios')
        mock.write_text('#!/usr/bin/env python3\nimport os\nwith open(os.environ["READY"], "w") as f: f.write("ready\\n")\nwith open(os.environ["RELEASE"]) as f: f.read()\nprint("[]")\n')
        mock.chmod(0o755)
        ready, release = str(pathlib.Path(tmp, 'ready')), str(pathlib.Path(tmp, 'release'))
        os.mkfifo(ready)
        os.mkfifo(release)
        concurrent_env = dict(ENV, PATH=tmp + os.pathsep + ENV['PATH'], PI_POPUP_SESSION='concurrency', PI_POPUP_BIN='/missing/pi', TMPDIR=tmp, READY=ready, RELEASE=release)
        process = subprocess.Popen(['fish', str(SCRIPT), '--ensure-only'], env=concurrent_env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        with open(ready) as f:
            assert f.readline().strip() == 'ready'
        busy = run('fish', str(SCRIPT), '--ensure-only', env=concurrent_env, check=False)
        assert busy.returncode == 1 and 'busy' in busy.stderr, busy
        with open(release, 'w') as f:
            f.write('go')
        out, err = process.communicate(timeout=10)
        assert process.returncode == 127, (out, err)
        assert not list(pathlib.Path(tmp).glob('*.lock')), 'lock leaked on failure'
    print('PASS: concurrent initialization rejected; error releases lock')
finally:
    result = tuios('kill-server', check=False)
    if result.returncode:
        print('Cleanup failure:', result.stderr)
