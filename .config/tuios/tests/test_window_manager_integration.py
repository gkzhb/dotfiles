"""Integration test on a named disposable daemon, including a real attached client.

Uses PTYs and waits for actual output, never sends keys to the user's client.
"""
import fcntl
import faulthandler
import importlib.util
import json
import os
from pathlib import Path
import pty
import shutil
import shlex
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import threading
import time
import traceback
import unittest
import uuid

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("wm", ROOT / "window-manager.py")
wm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wm)


class Terminal:
    def __init__(self, argv, env):
        pid, self.fd = pty.fork()
        if pid == 0:
            fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 38, 160, 0, 0))
            os.execvpe(argv[0], argv, dict(env, TERM="xterm-256color"))
        self.pid, self.output = pid, b""
        self.condition = threading.Condition()
        self.stopped = False
        # Drain continuously, including during synchronous CLI calls. Otherwise
        # the test PTY fills and tuios cannot process switch-session requests.
        self.reader = threading.Thread(target=self._read, daemon=True)
        self.reader.start()

    def _read(self):
        while not self.stopped:
            try:
                chunk = os.read(self.fd, 65536)
            except OSError:
                break
            if not chunk:
                break
            with self.condition:
                self.output = (self.output + chunk)[-1000000:]
                self.condition.notify_all()
            if b"\x1b[6n" in chunk:
                self.send(b"\x1b[1;1R")

    def wait(self, marker, timeout=15):
        deadline = time.monotonic() + timeout
        with self.condition:
            while marker.decode() not in wm.plain(self.output.decode(errors="replace"), multiline=True):
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    raise AssertionError(f"Timed out waiting for {marker!r}: {wm.plain(self.output.decode(errors='replace'), multiline=True)[-6000:]!r}")
                self.condition.wait(remaining)
            self.output = b""  # Subsequent waits must observe a new screen.

    def send(self, keys):
        os.write(self.fd, keys)

    def close(self):
        self.stopped = True
        done, _ = os.waitpid(self.pid, os.WNOHANG)
        if not done:
            try:
                os.kill(self.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            os.waitpid(self.pid, os.WNOHANG)
        os.close(self.fd)


class IntegrationTests(unittest.TestCase):
    def test_real_daemon_moves_and_popup_follow(self):
        faulthandler.dump_traceback_later(45, repeat=False)
        server = "twm-" + uuid.uuid4().hex[:7]
        original = dict(os.environ)
        env = {k: v for k, v in original.items() if not k.startswith("TUIOS_")}
        env["TUIOS_SERVER"] = server
        env["SHELL"] = shutil.which("bash")
        with tempfile.TemporaryDirectory(prefix="twm-integration-") as directory:
            config = Path(directory) / "tuios"
            config.mkdir()
            binding = f"{shlex.quote(sys.executable)} {shlex.quote(str(ROOT / 'window-manager.py'))}"
            (config / "config.toml").write_text('[agents]\nenabled = true\n[keybindings]\nleader_key = "ctrl+b"\n'
                                               '\n[keybindings.prefix_mode]\nprefix_next_attention = []\n'
                                               '\n[[keybindings.command]]\nkey = "prefix+o"\ntype = "shell"\n'
                                               f'command = {json.dumps(binding)}\nname = "window-manager"\n')
            env["XDG_CONFIG_HOME"] = directory
            os.environ.clear()
            os.environ.update(env)
            client = None
            def tuios(*args, check=True):
                return subprocess.run(["tuios", "--server", server, *map(str, args)],
                                      env=env, capture_output=True, text=True, check=check, timeout=20)
            api = wm.Tuios()
            try:
                # `call` only connects; `new --detach` is the documented daemon bootstrap.
                tuios("new", "--detach", "bootstrap")
                for name in ("source", "target"):
                    result = tuios("call", "new-session", json.dumps({"name": name, "window_name": name + "-one",
                                                                        "command": ["/bin/sleep", "300"]}), check=False)
                    self.assertEqual(result.returncode, 0, (result.stdout, result.stderr))
                source = next(s for s in api.sessions() if s["name"] == "source")
                target = next(s for s in api.sessions() if s["name"] == "target")
                first = api.windows(source["id"])["windows"][0]
                second_id = tuios("new-window", "second", "-s", "source", "--no-focus", "--print-id",
                                  "--", "/bin/sleep", "300").stdout.strip()
                tuios("set-window", "-s", "source", "-w", second_id, "--name", "second ' $(bad)\n\x1b[31mred")
                ctx = {"session": source["id"], "name": "source", "workspace": 1, "active": first["window_id"]}
                chosen = api.windows(source["id"])["windows"]
                moved, failures = wm.move_windows(api, ctx, chosen, {"session": source["id"], "workspace": 2})
                self.assertEqual(len(moved), 2)
                self.assertFalse(failures)
                ctx["workspace"] = 2
                same_pid = {w["window_id"]: w["pid"] for w in api.windows(source["id"])["windows"]}
                moved, failures = wm.move_windows(api, ctx, chosen, {"session": target["id"], "workspace": 3})
                self.assertFalse(failures)
                destination = api.windows(target["id"])["windows"]
                self.assertEqual({w["window_id"]: w["pid"] for w in destination if w["window_id"] in moved}, same_pid)
                self.assertTrue(all(w["workspace"] == 3 for w in destination if w["window_id"] in moved))
                print("PASS: same/cross-session batch moves preserve full IDs and PIDs", flush=True)

                # Move both disposable panes back; attach a test-only tuios client.
                for identity in (first["window_id"], second_id):
                    tuios("move-window", 1, "-s", "target", "-w", identity, "--to-session", "source")
                tuios("focus-window", "-s", "source", first["window_id"])
                client = Terminal(["tuios", "--server", server, "attach", "source"], env)
                client.wait(b"source-one")
                context = wm.context(api, "source")
                state = Path(directory) / "state"
                state.mkdir()
                wm.save(state / "context.json", context)
                popup = subprocess.Popen(["tuios", "--server", server, "popup", "-s", "source", "--wait",
                                          "--width", "95%", "--height", "90%", "--", sys.executable,
                                          str(ROOT / "window-manager.py"), "--view", str(state)],
                                         env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                try:
                    client.wait(b"Enter actions")
                    listing = api.windows(source["id"])
                    # Real version omits popup=true: the pinned allowlist must exclude it.
                    self.assertGreater(len(listing["windows"]), len(wm.source_windows(api, context)))
                    self.assertEqual({w["window_id"] for w in wm.source_windows(api, context)}, {first["window_id"], second_id})
                    client.send(b"\t\t\x18")  # Real multi-select → native Ctrl+X menu.
                    client.wait(b"Focus window")
                    client.send(b"move_follow\r")
                    client.wait(b"Move and follow")
                    client.send(b"target 2")
                    client.wait(b"target / 2")
                    client.send(b"\r")
                    out, err = popup.communicate(timeout=15)
                    self.assertEqual(popup.returncode, 0, (out, err))
                    intent = wm.load(state / "intent.json")
                    self.assertEqual(intent["session"], target["id"])
                    self.assertEqual(intent["workspace"], 2)
                    wm.apply_intent(api, context, intent)
                    clients = api.run("list-clients")
                    self.assertTrue(any(c["client_id"] == context["client"] and c["session"] == "target" for c in clients))
                    self.assertEqual(api.windows(target["id"])["current_workspace"], 2)
                    current = api.windows(target["id"])["windows"]
                    self.assertTrue(all(w["workspace"] == 2 and w["pid"] == same_pid[w["window_id"]]
                                        for w in current if w["window_id"] in same_pid))
                    print("PASS: native Ctrl+X batch action excludes popup, preserves PIDs and follows exact client", flush=True)
                    client.wait(b"source-one")
                    # Exercise the public launcher: it must wait for the popup,
                    # close it, then focus the target without restarting processes.
                    launcher_env = dict(env, TUIOS_SESSION="target")
                    launcher = subprocess.Popen([sys.executable, str(ROOT / "window-manager.py")],
                                                env=launcher_env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                    try:
                        client.wait(b"Enter actions")
                        client.send(b"\r")
                        client.wait(b"Focus window")
                        client.send(b"focus\r")
                        output, error = launcher.communicate(timeout=15)
                        self.assertEqual(launcher.returncode, 0, (output, error))
                        current = api.windows(target["id"])
                        self.assertEqual(current["focused_window_id"], first["window_id"])
                        self.assertEqual(current["current_workspace"], 2)
                        self.assertEqual(len(current["windows"]), 3)  # no retained popup
                        print("PASS: public launcher → Enter action menu → focus closes popup and preserves target focus", flush=True)
                        client.wait(b"source-one")
                        client.send(b"\x02o")  # Actual config command dispatch, not run-command.
                        client.wait(b"Enter actions")
                        client.send(b"\x03")
                        client.wait(b"source-one")
                        self.assertEqual(len(api.windows(target["id"])["windows"]), 3)
                        print("PASS: actual Leader+o shell binding opens manager, Ctrl+C closes without moving", flush=True)
                    finally:
                        if launcher.poll() is None:
                            launcher.terminate()
                            launcher.communicate(timeout=5)
                finally:
                    if popup.poll() is None:
                        popup.terminate()
                        popup.communicate(timeout=5)
            except BaseException:
                traceback.print_exc()
                raise
            finally:
                try:
                    tuios("kill-server", check=False)
                finally:
                    if client:
                        client.close()
                    os.environ.clear()
                    os.environ.update(original)
                    faulthandler.cancel_dump_traceback_later()


if __name__ == "__main__":
    unittest.main(verbosity=2)
