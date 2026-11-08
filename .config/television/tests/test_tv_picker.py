#!/usr/bin/env python3
"""Actual tv PTY tests. Only temporary Git repos and a recording editor are used."""
import fcntl
import importlib.util
import json
import os
from pathlib import Path
import pty
import select
import shlex
import shutil
import struct
import subprocess
import sys
import tempfile
import termios
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('tv_helper', ROOT / 'tv-helper.py')
h = importlib.util.module_from_spec(spec)
spec.loader.exec_module(h)


@unittest.skipUnless(shutil.which('tv') and shutil.which('fish'), 'tv and fish required')
class PickerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='tv real picker ')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.home = self.root / 'home'
        config = self.home / '.config/television'
        config.mkdir(parents=True)
        (config / 'tv-helper.py').symlink_to(ROOT / 'tv-helper.py')
        self.config = self.root / 'config.toml'
        self.config.write_text('shell="fish"\nhistory_size=0\n')
        self.repo = self.root / 'repo'
        self.repo.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), TERM='xterm-256color',
                        SHELL=shutil.which('fish'), XDG_DATA_HOME=str(self.root / 'data'),
                        XDG_CONFIG_HOME=str(self.home / '.config'),
                        XDG_CACHE_HOME=str(self.root / 'cache'),
                        GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_SYSTEM=os.devnull)
        for argv in [('init', '-q'), ('config', 'user.name', 'Test'),
                     ('config', 'user.email', 'test@example.invalid')]:
            subprocess.run(['git', *argv], cwd=self.repo, env=self.env, check=True, capture_output=True)

    def picker(self, channel, source=None, key=None, marker=None):
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('HHHH', 24, 100, 0, 0))
        argv = ['tv', channel, '--config-file', str(self.config), '--cable-dir',
                str(ROOT / 'cable'), '--no-remote']
        if source:
            argv += ['--source-command', source]
        if key is None:
            argv += ['--take-1']
        process = subprocess.Popen(argv, cwd=self.repo, stdin=slave, stderr=slave,
                                   stdout=subprocess.PIPE, env=self.env)
        os.close(slave)
        screen = b''
        sent = False
        deadline = time.monotonic() + 8
        try:
            while process.poll() is None and time.monotonic() < deadline:
                ready, _, _ = select.select([master], [], [], 0.1)
                if ready:
                    try:
                        chunk = os.read(master, 65536)
                    except OSError:
                        break
                    screen += chunk
                    if b'\x1b[6n' in chunk:
                        os.write(master, b'\x1b[1;1R')
                    if b'\x1b[c' in chunk:
                        os.write(master, b'\x1b[?1;2c')
                if key is not None and not sent and marker in screen:
                    os.write(master, key)
                    sent = True
            if process.poll() is None:
                process.kill()
            output = process.communicate(timeout=2)[0]
            self.assertEqual(process.returncode, 0, screen[-3000:].decode(errors='replace'))
            return output
        finally:
            if process.poll() is None:
                process.kill()
                process.communicate()
            os.close(master)

    def test_preview_unusual_filename_cannot_execute_shell(self):
        name = "name'; touch SAFE_PROBE; #\n中文.txt"
        (self.repo / name).write_text('preview-contents')
        output = self.picker('git-changed-files')
        value = output.decode().strip()
        self.assertEqual(h.decode(value), [str(self.repo), name])
        self.assertFalse((self.repo / 'SAFE_PROBE').exists())

    def test_edit_action_receives_token_not_display_label(self):
        name = "name'; touch SAFE_PROBE; #.txt"
        (self.repo / name).write_text('EDITOR_TARGET')
        record = self.root / 'argv.json'
        editor = self.root / 'record editor.py'
        editor.write_text('import json,pathlib,sys\npathlib.Path(sys.argv[1]).write_text(json.dumps(sys.argv[2:]))\n')
        self.env['EDITOR'] = f'{shlex.quote(sys.executable)} {shlex.quote(str(editor))} {shlex.quote(str(record))}'
        self.picker('git-changed-files', key=b'\x05', marker=b'EDITOR_TARGET')
        self.assertEqual(json.loads(record.read_text()), ['--', str(self.repo / name)])
        self.assertFalse((self.repo / 'SAFE_PROBE').exists())

    def test_worktree_selection_decodes_actual_path(self):
        output = self.picker('git-worktrees')
        self.assertEqual(h.decode(output.decode().strip()), str(self.repo))


if __name__ == '__main__':
    unittest.main()
