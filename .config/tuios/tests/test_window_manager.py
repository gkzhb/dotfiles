"""Unit tests and real Television PTY tests; no live-user daemon mutations."""
import fcntl
import importlib.util
import json
import os
from pathlib import Path
import pty
import select
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("window_manager", ROOT / "window-manager.py")
wm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wm)
CTX = {"session": "source-id", "name": "source", "workspace": 1, "client": "client-a", "active": "a"}


class FakeAPI:
    def __init__(self):
        self.rows = [{"window_id": "a", "workspace": 1, "display_name": "alpha", "pid": 123},
                     {"window_id": "b", "workspace": 1, "display_name": "beta", "pid": 456}]
        self.calls = []
        self.fail = set()

    def sessions(self):
        return [{"id": "source-id", "name": "source"}, {"id": "target-id", "name": "target"}]

    def windows(self, session):
        return {"current_workspace": 1, "windows": self.rows, "focused_window_id": "a"}

    def workspaces(self, session):
        return {"workspaces": [{"workspace": n, "window_count": 0} for n in (1, 2, 3, 1000)]}

    def run(self, *args, **kw):
        self.calls.append(args)
        if args[0] == "list-clients":
            return [{"client_id": "client-a", "session": "source"}]
        if args[0] == "move-window" and args[args.index("-w") + 1] in self.fail:
            raise wm.ManagerError("refused")
        return {}


def pty_picker(directory, keys, windows=True, env=None):
    """Exercise the installed tv, not a mock. Bound waits to actual screen text."""
    outcome = Path(directory) / "outcome.json"
    pid, master = pty.fork()
    if pid == 0:
        try:
            os.environ.update(env or {})
            os.environ["TERM"] = "xterm-256color"
            fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 32, 140, 0, 0))
            choice = wm.Picker(directory).choose(
                {"w0": {"label": "alpha"}, "w1": {"label": "beta"}},
                "PICKER-READY", windows=windows, preview=False)
            wm.save(outcome, choice)
            os._exit(0)
        except BaseException as exc:
            wm.save(outcome, {"error": repr(exc)})
            os._exit(1)
    screen = b""
    sent = False
    deadline = time.monotonic() + 12
    try:
        while time.monotonic() < deadline:
            ready, _, _ = select.select([master], [], [], max(0, deadline - time.monotonic()))
            if not ready:
                break
            try:
                chunk = os.read(master, 65536)
            except OSError:
                break
            if not chunk:
                break
            screen += chunk
            if b"\x1b[6n" in chunk:
                os.write(master, b"\x1b[1;1R")
            if not sent and b"alpha" in screen and b"beta" in screen:
                os.write(master, keys)
                sent = True
        if not outcome.exists():
            raise AssertionError(f"tv did not finish: {screen[-3500:]!r}")
        return wm.load(outcome)
    finally:
        done, _ = os.waitpid(pid, os.WNOHANG)
        if not done:
            try:
                os.kill(pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            os.waitpid(pid, 0)
        os.close(master)


class UnitTests(unittest.TestCase):
    def test_cli_resolves_session_uuid_to_current_name(self):
        identity = "00000000-1111-2222-3333-444444444444"
        api = wm.Tuios()
        with patch.object(api, "sessions", return_value=[{"id": identity, "name": "renamed"}]):
            with patch.object(wm.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, "{}", "")) as run:
                api.run("list-windows", "-s", identity)
                self.assertEqual(run.call_args.args[0], ["tuios", "list-windows", "-s", "renamed", "--json"])
        with patch.object(api, "sessions", return_value=[{"id": "other", "name": "renamed"}]):
            with self.assertRaises(wm.ManagerError):
                api.run("list-windows", "-s", identity)

    def test_tv_parse_error_is_not_cancellation(self):
        with tempfile.TemporaryDirectory() as directory:
            original = subprocess.Popen
            def invalid(*args, **kwargs):
                return original([sys.executable, "-c", "import sys; print('Error parsing CLI arguments', file=sys.stderr); sys.exit(1)"], **kwargs)
            with patch.object(wm.subprocess, "Popen", side_effect=invalid):
                with self.assertRaisesRegex(wm.ManagerError, "Error parsing"):
                    wm.Picker(directory).choose({"w0": {"label": "alpha"}}, "test", windows=True)

    def test_sanitize_and_filter(self):
        self.assertEqual(wm.plain("x\x1b[31mr\x1b[0m\x1b]52;c;secret\x07\n\t\u202e"), "xr   ")
        for key in ("popup", "scratch", "host", "hosted"):
            self.assertFalse(wm.movable({key: True}))
        self.assertTrue(wm.movable({}))

    def test_pinned_snapshot_excludes_popup_and_late_windows(self):
        api = FakeAPI()
        ctx = dict(CTX, window_ids=["a"])
        self.assertEqual([w["window_id"] for w in wm.source_windows(api, ctx)], ["a"])
        api.rows.append({"window_id": "popup", "workspace": 1})
        self.assertEqual([w["window_id"] for w in wm.source_windows(api, ctx)], ["a"])

    def test_entries_hide_ids_and_controls(self):
        rows = [{"window_id": "a", "workspace": 1, "title": "$(touch /tmp/evil)\n\x1b[31mx", "cwd": "a\tb"}]
        entry = wm.window_entries(rows, CTX)["w0"]
        self.assertIn("$(touch /tmp/evil)", entry["label"])
        self.assertNotIn("\n", entry["label"])
        self.assertNotIn("\t", entry["label"])
        self.assertNotIn("\x1b", entry["label"])
        self.assertEqual(entry["window"]["window_id"], "a")

    def test_destinations_empty_and_ordered(self):
        targets = list(wm.destinations(FakeAPI(), CTX).values())
        self.assertEqual([(t["session"], t["workspace"]) for t in targets],
                         [("source-id", 2), ("source-id", 3), ("target-id", 1), ("target-id", 2), ("target-id", 3)])

    def test_context_requires_explicit_unambiguous_client(self):
        api = FakeAPI()
        self.assertEqual(wm.context(api, "source")["session"], "source-id")
        with self.assertRaises(wm.ManagerError):
            wm.context(api, "source", "other")

    def test_partial_failure_no_follow_no_rollback(self):
        api = FakeAPI()
        api.fail.add("b")
        moved, errors = wm.move_windows(api, CTX, api.rows, {"session": "target-id", "workspace": 2})
        self.assertEqual(moved, ["a"])
        self.assertEqual(len(errors), 1)
        self.assertEqual(len(api.calls), 2)
        self.assertTrue(all("--follow" not in call for call in api.calls))
        self.assertTrue(all("--to-session" in call for call in api.calls))

    def test_stale_window_is_never_moved(self):
        api = FakeAPI()
        selected = dict(api.rows[0])
        api.rows[0]["workspace"] = 3
        moved, errors = wm.move_windows(api, CTX, [selected], {"session": "target-id", "workspace": 2})
        self.assertEqual(moved, [])
        self.assertEqual(len(errors), 1)
        self.assertFalse(api.calls)

    def test_replaced_destination_same_name_is_rejected(self):
        api = FakeAPI()
        with self.assertRaises(wm.ManagerError):
            wm.move_windows(api, CTX, api.rows, {"session": "deleted-id", "name": "target", "workspace": 2})
        self.assertFalse(api.calls)

    def test_switched_client_is_not_followed(self):
        api = FakeAPI()
        api.run = lambda *a, **kw: [{"client_id": "client-a", "session": "target"}]
        with self.assertRaises(wm.ManagerError):
            wm.apply_intent(api, CTX, {"session": "target-id", "workspace": 1, "window": "a"})

    def test_same_session_uses_no_to_session(self):
        api = FakeAPI()
        wm.move_windows(api, CTX, [api.rows[0]], {"session": "source-id", "workspace": 2})
        self.assertNotIn("--to-session", api.calls[0])

    def test_follow_checks_client_and_exact_location(self):
        api = FakeAPI()
        wm.apply_intent(api, CTX, {"session": "target-id", "workspace": 1, "window": "a"})
        self.assertEqual(api.calls[-1], ("switch-session", "target-id", "--client", "client-a"))
        api.rows[0]["workspace"] = 2
        before = len(api.calls)
        with self.assertRaises(wm.ManagerError):
            wm.apply_intent(api, CTX, {"session": "target-id", "workspace": 1, "window": "a"})
        self.assertEqual(len(api.calls), before + 1)  # client read only

    def test_escape_menu_and_destination_never_mutate(self):
        api = FakeAPI()
        class Picker:
            def __init__(self):
                self.n = 0
            def choose(self, entries, header, **kw):
                self.n += 1
                if self.n == 1:
                    return "alt-m", [next(iter(entries.values()))]
                return "cancel", []
        with tempfile.TemporaryDirectory() as directory:
            wm.manage(api, CTX, directory, Picker())
            self.assertFalse((Path(directory) / "intent.json").exists())
        self.assertFalse(api.calls)

    def test_batch_follow_writes_intent_only_after_success(self):
        api = FakeAPI()
        class Picker:
            def choose(self, entries, header, **kw):
                if kw.get("windows"):
                    return "alt-g", list(entries.values())
                return "enter", [next(v for v in entries.values() if v.get("session") == "target-id")]
        with tempfile.TemporaryDirectory() as directory:
            wm.manage(api, CTX, directory, Picker())
            self.assertEqual(wm.load(Path(directory) / "intent.json")["window"], "a")
        self.assertEqual(sum(c[0] == "move-window" for c in api.calls), 2)
        self.assertFalse(any(c[0] in ("focus-window", "switch-session") for c in api.calls))


class TelevisionTests(unittest.TestCase):
    def test_escape_returns_without_selection(self):
        with tempfile.TemporaryDirectory() as directory:
            self.assertEqual(pty_picker(directory, b"\x1b"), ["cancel", []])

    def test_expect_enter_outputs_token(self):
        with tempfile.TemporaryDirectory() as directory:
            result = pty_picker(directory, b"\r")
            self.assertEqual(result, ["enter", [{"label": "alpha"}]])

    def test_alt_follow_and_focus(self):
        for key in ("g", "f"):
            with self.subTest(key=key), tempfile.TemporaryDirectory() as directory:
                self.assertEqual(pty_picker(directory, b"\x1b" + key.encode()),
                                 ["alt-" + key, [{"label": "alpha"}]])

    def test_alt_move_and_tab_multiselect(self):
        with tempfile.TemporaryDirectory() as directory:
            result = pty_picker(directory, b"\t\t\x1bm")
            self.assertEqual(result, ["alt-m", [{"label": "alpha"}, {"label": "beta"}]])

    def test_ctrl_r_returns_even_without_mutation(self):
        with tempfile.TemporaryDirectory() as directory:
            self.assertEqual(pty_picker(directory, b"\x12"), ["ctrl-r", []])

    def test_cancel(self):
        with tempfile.TemporaryDirectory() as directory:
            self.assertEqual(pty_picker(directory, b"\x03"), ["cancel", []])

    def test_destination_enter_has_no_expect_line(self):
        with tempfile.TemporaryDirectory() as directory:
            self.assertEqual(pty_picker(directory, b"\r", windows=False), ["enter", [{"label": "alpha"}]])


if __name__ == "__main__":
    unittest.main(verbosity=2)
