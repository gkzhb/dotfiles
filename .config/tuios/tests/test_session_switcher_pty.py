"""Real Television PTY contract tests. Never starts or calls a tuios daemon."""
import fcntl
import json
import os
from pathlib import Path
import pty
import re
import shutil
import signal
import struct
import sys
import termios
import threading
import time
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'session-switcher.py'
WORKER = '''
import importlib.util, json, sys
spec = importlib.util.spec_from_file_location('picker', sys.argv[1])
picker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(picker)
record = {'name': '-name "with spaces"', 'id': '12345678-1234-1234-1234-123456789abc',
          'fields': [' ', 'name', 'repo', 'main', 'dir', 'dev', '1', 'detached'], 'preview': 'PREVIEW'}
records = [record]
if sys.argv[2] == 'multiple':
    records.append(dict(record, name='second-session',
                        fields=[' ', 'second-session', 'other-repo', 'feature', 'other-dir', 'topic', '2', 'attached'],
                        preview='SECOND PREVIEW'))
result = picker.confirm_kill(record) if sys.argv[2] == 'confirm' else picker.choose(records)
print('RESULT=' + json.dumps(result), flush=True)
'''


class Terminal:
    def __init__(self, mode):
        self.pid, self.fd = pty.fork()
        if self.pid == 0:
            fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', 34, 180, 0, 0))
            env = dict(os.environ, TERM='xterm-256color', SHELL='/bin/fish',
                       FZF_DEFAULT_OPTS='--multi --expect=ctrl-x')
            os.execve(sys.executable, [sys.executable, '-c', WORKER, str(SCRIPT), mode], env)
        self.output = b''
        self.condition = threading.Condition()
        self.reader = threading.Thread(target=self.read, daemon=True)
        self.reader.start()

    def read(self):
        while True:
            try:
                chunk = os.read(self.fd, 65536)
            except OSError:
                break
            if not chunk:
                break
            with self.condition:
                self.output += chunk
                self.condition.notify_all()
            if b'\x1b[6n' in chunk:
                os.write(self.fd, b'\x1b[1;1R')
        with self.condition:
            self.condition.notify_all()

    def wait(self, marker):
        deadline = time.monotonic() + 10
        with self.condition:
            while True:
                output = re.sub(rb'\x1b\[[0-?]*[ -/]*[@-~]', b'', self.output)
                if marker in output:
                    return output
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    raise AssertionError(f'Timed out waiting for {marker!r}: {output[-4000:]!r}')
                self.condition.wait(remaining)

    def result(self):
        output = self.wait(b'RESULT=')
        return json.loads(output.split(b'RESULT=', 1)[1].splitlines()[0])

    def close(self):
        done, _ = os.waitpid(self.pid, os.WNOHANG)
        if not done:
            try:
                os.kill(self.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            os.waitpid(self.pid, 0)
        os.close(self.fd)
        self.reader.join(timeout=1)


@unittest.skipUnless(shutil.which('tv') and shutil.which('bash'), 'tv/bash not installed')
class TelevisionPTYTests(unittest.TestCase):
    def test_enter_and_ctrl_r_return_action_with_exact_record(self):
        for keys, action in ((b'\r', 'switch'), (b'\x12', 'kill')):
            with self.subTest(action=action):
                terminal = Terminal('choose')
                try:
                    terminal.wait(b'PREVIEW')  # Source and preview are loaded, not just the prompt.
                    os.write(terminal.fd, keys)
                    result = terminal.result()
                    self.assertEqual(result[0], action)
                    self.assertEqual(result[1]['name'], '-name "with spaces"')
                finally:
                    terminal.close()

    def test_source_ansi_colors_reach_rendered_fields(self):
        terminal = Terminal('choose')
        try:
            terminal.wait(b'PREVIEW')
            # Inspect tv's terminal output, not just the input rows' ANSI codes.
            foreground = None
            colored_text = []
            for part in re.split(rb'(\x1b\[[0-?]*[ -/]*[@-~])', terminal.output):
                if part.startswith(b'\x1b['):
                    if part.endswith(b'm'):
                        codes = [int(code or b'0') for code in part[2:-1].split(b';')]
                        i = 0
                        while i < len(codes):
                            code = codes[i]
                            if code in (0, 39):
                                foreground = None
                            elif 30 <= code <= 37:
                                foreground = code - 30
                            elif code == 38 and codes[i + 1:i + 2] == [5]:
                                foreground = codes[i + 2]
                                i += 2
                            elif code in (38, 48) and codes[i + 1:i + 2] == [2]:
                                i += 4
                            elif code == 48 and codes[i + 1:i + 2] == [5]:
                                i += 2
                            i += 1
                else:
                    colored_text.append((foreground, part))
            for field, color in ((b'repo', 6), (b'main', 5), (b'dir', 4), (b'dev', 3)):
                with self.subTest(field=field):
                    self.assertTrue(any(fg == color and field in chunk for fg, chunk in colored_text),
                                    f'{field!r} not rendered in ANSI color {color}: {colored_text[-25:]}')
        finally:
            terminal.close()

    def test_searches_display_fields_and_returns_exact_second_record(self):
        terminal = Terminal('multiple')
        try:
            terminal.wait(b'PREVIEW')
            os.write(terminal.fd, b'feature')
            terminal.wait(b'SECOND PREVIEW')
            os.write(terminal.fd, b'\r')
            result = terminal.result()
            self.assertEqual(result[0], 'switch')
            self.assertEqual(result[1]['name'], 'second-session')
        finally:
            terminal.close()

    def test_cancel_returns_no_selection(self):
        for keys in (b'\x1b', b'\x03'):
            with self.subTest(keys=keys):
                terminal = Terminal('choose')
                try:
                    terminal.wait(b'PREVIEW')
                    os.write(terminal.fd, keys)
                    self.assertIsNone(terminal.result())
                finally:
                    terminal.close()

    def test_tab_does_not_enable_multi_selection(self):
        terminal = Terminal('multiple')
        try:
            terminal.wait(b'PREVIEW')
            os.write(terminal.fd, b'\t\x1b[B')
            terminal.wait(b'SECOND PREVIEW')
            os.write(terminal.fd, b'\r')
            result = terminal.result()
            self.assertEqual(result[0], 'switch')
            self.assertEqual(result[1]['name'], 'second-session')
        finally:
            terminal.close()

    def test_confirmation_defaults_to_cancel_and_requires_down(self):
        for keys, confirmed in ((b'\r', False), (b'\x1b[B\r', True),
                                (b'\x03', False), (b'\x1b', False)):
            with self.subTest(confirmed=confirmed, keys=keys):
                terminal = Terminal('confirm')
                try:
                    terminal.wait(b'Cancel (keep session)')
                    os.write(terminal.fd, keys)
                    self.assertEqual(terminal.result(), confirmed)
                finally:
                    terminal.close()


if __name__ == '__main__':
    unittest.main()
