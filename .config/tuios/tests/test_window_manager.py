"""Unit tests and real Television PTY tests; no live-user daemon mutations."""
import fcntl
import importlib.util
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


def pty_picker(directory, keys, windows=True, env=None, menu_keys=None, after_menu_keys=None):
    """Exercise the installed tv, not a mock. Bound waits to actual screen text."""
    outcome = Path(directory) / "outcome.json"
    pid, master = pty.fork()
    if pid == 0:
        try:
            os.environ.update(env or {})
            os.environ.update(HOME=directory, XDG_CONFIG_HOME=str(Path(directory) / "config"),
                              XDG_DATA_HOME=str(Path(directory) / "data"),
                              XDG_STATE_HOME=str(Path(directory) / "state"),
                              XDG_CACHE_HOME=str(Path(directory) / "cache"))
            os.environ["TERM"] = "xterm-256color"
            fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 32, 140, 0, 0))
            wm.TV_ROOT = ROOT.parent / "television"
            choice = wm.Picker(directory).choose(
                {"w0": {"label": "alpha", "window": {"window_id": "a"}},
                 "w1": {"label": "beta", "window": {"window_id": "b"}}},
                "PICKER-READY", windows=windows, preview=False)
            wm.save(outcome, choice)
            os._exit(0)
        except BaseException as exc:
            wm.save(outcome, {"error": repr(exc)})
            os._exit(1)
    screen = b""
    sent = False
    menu_sent = False
    after_menu_sent = False
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
            elif menu_keys is not None and not menu_sent and b"Focus window" in screen:
                os.write(master, menu_keys)
                menu_sent = True
                if after_menu_keys is not None:
                    screen = b""
            elif menu_sent and after_menu_keys is not None and not after_menu_sent and b" CHANNEL " in screen:
                # Returning from a mode queues another action. Wait for its
                # rendered acknowledgement rather than batching the next key.
                os.write(master, after_menu_keys)
                after_menu_sent = True
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
                    return "move", [next(iter(entries.values()))]
                return "cancel", []
        with tempfile.TemporaryDirectory() as directory:
            wm.manage(api, CTX, directory, Picker())
            self.assertFalse((Path(directory) / "intent.json").exists())
        self.assertFalse(api.calls)

    def test_normal_move_returns_to_window_list_without_follow(self):
        api = FakeAPI()
        class Picker:
            calls = 0
            def choose(self, entries, header, **kw):
                self.calls += 1
                if self.calls == 1:
                    return "move", [next(iter(entries.values()))]
                if self.calls == 2:
                    return "enter", [next(v for v in entries.values() if v.get("session") == "target-id")]
                self.assert_header = header
                return "cancel", []
        picker = Picker()
        with tempfile.TemporaryDirectory() as directory:
            wm.manage(api, CTX, directory, picker)
            self.assertFalse((Path(directory) / "intent.json").exists())
        self.assertEqual(picker.calls, 3)
        self.assertIn("Moved 1/1", picker.assert_header)
        self.assertEqual(sum(c[0] == "move-window" for c in api.calls), 1)
        self.assertFalse(any(c[0] in ("focus-window", "switch-session") for c in api.calls))

    def test_multiselect_focus_is_rejected_without_intent(self):
        api = FakeAPI()
        class Picker:
            calls = 0
            def choose(self, entries, header, **kw):
                self.calls += 1
                return ("focus", list(entries.values())) if self.calls == 1 else ("cancel", [])
        with tempfile.TemporaryDirectory() as directory:
            wm.manage(api, CTX, directory, Picker())
            self.assertFalse((Path(directory) / "intent.json").exists())
        self.assertFalse(api.calls)

    def test_partial_batch_follow_never_writes_intent(self):
        api = FakeAPI()
        api.fail.add("b")
        class Picker:
            calls = 0
            def choose(self, entries, header, **kw):
                self.calls += 1
                if self.calls == 1:
                    return "follow", list(entries.values())
                if self.calls == 2:
                    return "enter", [next(v for v in entries.values() if v.get("session") == "target-id")]
                return "cancel", []
        with tempfile.TemporaryDirectory() as directory, patch.object(wm, "notice", return_value=True):
            wm.manage(api, CTX, directory, Picker())
            self.assertFalse((Path(directory) / "intent.json").exists())
        self.assertFalse(any(c[0] in ("focus-window", "switch-session") for c in api.calls))

    def test_batch_follow_writes_intent_only_after_success(self):
        api = FakeAPI()
        class Picker:
            def choose(self, entries, header, **kw):
                if kw.get("windows"):
                    return "follow", list(entries.values())
                return "enter", [next(v for v in entries.values() if v.get("session") == "target-id")]
        with tempfile.TemporaryDirectory() as directory:
            wm.manage(api, CTX, directory, Picker())
            self.assertEqual(wm.load(Path(directory) / "intent.json")["window"], "a")
        self.assertEqual(sum(c[0] == "move-window" for c in api.calls), 2)
        self.assertFalse(any(c[0] in ("focus-window", "switch-session") for c in api.calls))


class RequestTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.directory = Path(self.temp.name)
        self.entries = {"w0": {"label": "alpha", "window": {"window_id": "a"}},
                        "w1": {"label": "$(touch bad) ' beta", "window": {"window_id": "b"}}}
        wm.save(self.directory / "entries.json", self.entries)
        wm.save(self.directory / "picker.json", {"id": "current", "windows": True})

    def tearDown(self):
        self.temp.cleanup()

    def test_request_only_records_tokens_and_preserves_source_order(self):
        with patch.object(wm, "Tuios", side_effect=AssertionError("No tuios in request helper")):
            wm.request_action(self.directory, "current", "follow", ["w1", "w0", "w1"])
        self.assertEqual(wm.consume_request(self.directory, "current", self.entries),
                         ("follow", list(self.entries.values())))
        self.assertFalse((self.directory / "request.json").exists())

    def test_invalid_action_token_and_picker_are_rejected_without_request(self):
        for identity, action, tokens in (("old", "move", ["w0"]), ("current", "kill", ["w0"]),
                                        ("current", "move", []), ("current", "move", ["w9"]),
                                        ("current", "move", ["w0; touch bad"]),
                                        ("current", "move", ["d0"])):
            with self.subTest(action=action, tokens=tokens), self.assertRaises(wm.ManagerError):
                wm.request_action(self.directory, identity, action, tokens)
        self.assertFalse((self.directory / "request.json").exists())

    def test_destination_picker_cannot_submit_window_actions(self):
        wm.save(self.directory / "picker.json", {"id": "current", "windows": False})
        with self.assertRaises(wm.ManagerError):
            wm.request_action(self.directory, "current", "move", ["w0"])

    def test_stale_malformed_and_unknown_requests_consumed_once(self):
        for request in ({"picker": "old", "action": "move", "tokens": ["w0"]},
                        {"picker": "current", "action": "kill", "tokens": ["w0"]},
                        {"picker": "current", "action": "move", "tokens": ["w9"]},
                        {"picker": "current", "action": "focus", "tokens": "w0"}, []):
            wm.save(self.directory / "request.json", request)
            with self.subTest(request=request), self.assertRaises(wm.ManagerError):
                wm.consume_request(self.directory, "current", self.entries)
            self.assertFalse((self.directory / "request.json").exists())
        (self.directory / "request.json").write_text("not JSON")
        with self.assertRaises(wm.ManagerError):
            wm.consume_request(self.directory, "current", self.entries)
        self.assertFalse((self.directory / "request.json").exists())

    def test_tv_error_discards_written_request_and_does_not_select(self):
        original = subprocess.Popen
        def failed(*args, **kwargs):
            identity = kwargs["env"]["TWM_PICKER"]
            wm.save(self.directory / "request.json", {"picker": identity, "action": "focus", "tokens": ["w0"]})
            return original([sys.executable, "-c", "raise SystemExit(1)"], **kwargs)
        with patch.object(wm.subprocess, "Popen", side_effect=failed), self.assertRaises(wm.ManagerError):
            wm.Picker(self.directory).choose(self.entries, "test", windows=True)
        self.assertFalse((self.directory / "request.json").exists())

    def test_raw_output_and_request_conflict_is_rejected(self):
        original = subprocess.Popen
        def conflict(*args, **kwargs):
            wm.save(self.directory / "request.json", {"picker": kwargs["env"]["TWM_PICKER"],
                                                     "action": "focus", "tokens": ["w0"]})
            return original([sys.executable, "-c", "print('w0')"], **kwargs)
        with patch.object(wm.subprocess, "Popen", side_effect=conflict), self.assertRaises(wm.ManagerError):
            wm.Picker(self.directory).choose(self.entries, "test", windows=True)
        self.assertFalse((self.directory / "request.json").exists())

    def test_unexpected_raw_window_output_is_not_an_action(self):
        original = subprocess.Popen
        def raw(*args, **kwargs):
            return original([sys.executable, "-c", "print('w0')"], **kwargs)
        with patch.object(wm.subprocess, "Popen", side_effect=raw), self.assertRaises(wm.ManagerError):
            wm.Picker(self.directory).choose(self.entries, "test", windows=True)

    def test_cancel_removes_previous_request_before_starting_tv(self):
        wm.save(self.directory / "request.json", {"picker": "old", "action": "focus", "tokens": ["w0"]})
        original = subprocess.Popen
        def cancelled(*args, **kwargs):
            return original([sys.executable, "-c", "pass"], **kwargs)
        with patch.object(wm.subprocess, "Popen", side_effect=cancelled):
            self.assertEqual(wm.Picker(self.directory).choose(self.entries, "test", windows=True), ("cancel", []))
        self.assertFalse((self.directory / "request.json").exists())


class TelevisionTests(unittest.TestCase):
    alpha = {"label": "alpha", "window": {"window_id": "a"}}
    beta = {"label": "beta", "window": {"window_id": "b"}}
    def test_escape_returns_without_selection(self):
        with tempfile.TemporaryDirectory() as directory:
            self.assertEqual(pty_picker(directory, b"\x1b"), ["cancel", []])

    def test_native_enter_menu_focus(self):
        with tempfile.TemporaryDirectory() as directory:
            result = pty_picker(directory, b"\r", menu_keys=b"focus\r")
            self.assertEqual(result, ["focus", [self.alpha]])

    def test_native_ctrl_x_menu_multiselect_move(self):
        with tempfile.TemporaryDirectory() as directory:
            result = pty_picker(directory, b"\t\t\x18", menu_keys=b"move\r")
            self.assertEqual(result, ["move", [self.alpha, self.beta]])

    def test_native_menu_escape_returns_then_cancel(self):
        with tempfile.TemporaryDirectory() as directory:
            self.assertEqual(pty_picker(directory, b"\x18", menu_keys=b"\x1b", after_menu_keys=b"\x03"), ["cancel", []])

    def test_native_menu_toggle_back_then_direct_action(self):
        with tempfile.TemporaryDirectory() as directory:
            self.assertEqual(pty_picker(directory, b"\x18", menu_keys=b"\x18", after_menu_keys=b"\x1bm"),
                             ["move", [self.alpha]])

    def test_alt_follow_and_focus(self):
        for key, action in (("g", "follow"), ("f", "focus")):
            with self.subTest(key=key), tempfile.TemporaryDirectory() as directory:
                self.assertEqual(pty_picker(directory, b"\x1b" + key.encode()),
                                 [action, [self.alpha]])

    def test_alt_move_and_tab_multiselect(self):
        with tempfile.TemporaryDirectory() as directory:
            result = pty_picker(directory, b"\t\t\x1bm")
            self.assertEqual(result, ["move", [self.alpha, self.beta]])

    def test_ctrl_r_returns_even_without_mutation(self):
        with tempfile.TemporaryDirectory() as directory:
            self.assertEqual(pty_picker(directory, b"\x12"), ["ctrl-r", []])

    def test_cancel(self):
        with tempfile.TemporaryDirectory() as directory:
            self.assertEqual(pty_picker(directory, b"\x03"), ["cancel", []])

    def test_destination_enter_has_no_expect_line(self):
        with tempfile.TemporaryDirectory() as directory:
            self.assertEqual(pty_picker(directory, b"\r", windows=False), ["enter", [self.alpha]])


if __name__ == "__main__":
    unittest.main(verbosity=2)
