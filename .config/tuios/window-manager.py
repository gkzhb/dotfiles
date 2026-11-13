#!/usr/bin/env python3
"""Television window manager for tuios. No third-party Python dependencies."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import unicodedata

ROOT = Path(__file__).resolve().parent
TV_ROOT = Path.home() / ".config" / "television"
ANSI = re.compile(r"\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)|\x1b\[[0-?]*[ -/]*[@-~]")
TOKEN = re.compile(r"[wdma][0-9]+\Z")


class ManagerError(Exception):
    pass


def plain(value, multiline=False):
    """Never render terminal controls supplied by titles, commands or output."""
    text = ANSI.sub("", str(value or ""))
    return "".join(c if not unicodedata.category(c).startswith("C") else
                   ("\n" if multiline and c == "\n" else " ") for c in text)


def save(path, data):
    path = Path(path)
    temporary = path.with_suffix(".new")
    temporary.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
    temporary.replace(path)


def load(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


class Tuios:
    def run(self, *args, json_output=True, timeout=20):
        args = list(map(str, args))
        # tuios 0.10.1 exposes session UUIDs but -s resolves NAMES only.
        # Keep immutable IDs in our state; resolve them immediately before each
        # invocation instead of mistaking a replacement with the same name.
        session_positions = [i + 1 for i, value in enumerate(args[:-1])
                             if value in ("-s", "--session", "--to-session")]
        if args and args[0] == "switch-session" and len(args) > 1:
            session_positions.append(1)
        identities = [i for i in session_positions if re.fullmatch(r"[0-9a-f-]{36}", args[i])]
        if identities:
            sessions = self.sessions()
            for i in identities:
                match = next((s for s in sessions if s["id"] == args[i]), None)
                if match is None:
                    raise ManagerError("Session disappeared; refusing to use a replacement name.")
                args[i] = match["name"]
        argv = ["tuios", *args]
        if json_output:
            argv.append("--json")
        try:
            result = subprocess.run(argv, capture_output=True, text=True, timeout=timeout)
        except subprocess.TimeoutExpired as exc:
            raise ManagerError("tuios timed out; outcome may be unknown. Inspect state before retrying.") from exc
        if result.returncode:
            raise ManagerError(plain(result.stderr or result.stdout or f"tuios exited {result.returncode}"))
        if not json_output:
            return result.stdout
        try:
            value = json.loads(result.stdout)
        except ValueError as exc:
            raise ManagerError("tuios returned invalid JSON; no automatic retry.") from exc
        if isinstance(value, dict) and (value.get("error") or value.get("success") is False):
            raise ManagerError(plain(value))
        return value

    def sessions(self):
        return self.run("ls")

    def windows(self, session):
        return self.run("list-windows", "-s", session)

    def workspaces(self, session):
        return self.run("list-workspaces", "-s", session)


def movable(window):
    return not any(window.get(key) for key in ("popup", "is_popup", "scratch", "host", "hosted"))


def session_by_id(api, identity):
    matches = [s for s in api.sessions() if s["id"] == identity]
    if len(matches) != 1:
        raise ManagerError("Session disappeared; refusing to guess a replacement.")
    return matches[0]


def context(api, session, client=None):
    if not session:
        raise ManagerError("Run inside the source tuios session, or pass --session NAME.")
    matches = [s for s in api.sessions() if session in (s["name"], s["id"])]
    if len(matches) != 1:
        raise ManagerError("Source session not found or ambiguous.")
    source = matches[0]
    clients = [c for c in api.run("list-clients") if c.get("session") == source["name"]]
    if client:
        clients = [c for c in clients if c["client_id"] == client]
    if len(clients) != 1:
        raise ManagerError("Need exactly one client showing the source session; use --client ID if ambiguous.")
    listing = api.windows(source["id"])
    return {"session": source["id"], "name": source["name"],
            "workspace": listing["current_workspace"], "client": clients[0]["client_id"],
            "active": os.environ.get("TUIOS_ACTIVE_PANE_ID") or listing.get("focused_window_id", ""),
            # tuios 0.10.1 list-windows omits popup=true. Pin pre-popup IDs so
            # our own popup (and any later popup) can never become an action target.
            "window_ids": [w["window_id"] for w in listing["windows"]
                           if w["workspace"] == listing["current_workspace"] and movable(w)]}


def source_windows(api, ctx):
    listing = api.windows(ctx["session"])
    return [w for w in listing["windows"]
            if w["workspace"] == ctx["workspace"] and movable(w)
            and ("window_ids" not in ctx or w["window_id"] in ctx["window_ids"])]


def window_entries(windows, ctx):
    entries = {}
    for index, window in enumerate(windows):
        marker = "●" if window["window_id"] == ctx["active"] else " "
        minimized = " [minimized]" if window.get("minimized") else ""
        name = plain(window.get("display_name") or window.get("title") or "terminal")
        cmd = plain(window.get("foreground_cmd") or "shell")
        cwd = plain(window.get("cwd") or "")
        label = f"{marker} {window.get('index', index)}  {name}{minimized}  ·  {cmd}  ·  {cwd}"
        entries[f"w{index}"] = {"label": label, "window": window}
    return entries


def destinations(api, ctx):
    sessions = api.sessions()
    sessions.sort(key=lambda s: s["id"] != ctx["session"])
    entries = {}
    for session in sessions:
        listing = api.workspaces(session["id"])
        for workspace in listing["workspaces"]:
            number = workspace["workspace"]
            if number >= 1000 or (session["id"] == ctx["session"] and number == ctx["workspace"]):
                continue
            count = workspace.get("window_count", 0)
            name = f" · {plain(workspace['name'])}" if workspace.get("name") else ""
            label = f"{plain(session['name'])} / {number}{name}    {str(count) + ' windows' if count else 'empty'}"
            entries[f"d{len(entries)}"] = {"label": label, "session": session["id"],
                                            "name": session["name"], "workspace": number}
    return entries


def validate_window(api, ctx, identity):
    current = next((w for w in source_windows(api, ctx) if w["window_id"] == identity), None)
    if current is None:
        raise ManagerError("Window closed, changed workspace/session, or is not movable.")
    return current


def validate_destination(api, ctx, target):
    session_by_id(api, target["session"])
    listing = api.workspaces(target["session"])
    if not any(w["workspace"] == target["workspace"] and w["workspace"] < 1000 for w in listing["workspaces"]):
        raise ManagerError("Destination workspace is no longer available.")
    if (ctx["session"], ctx["workspace"]) == (target["session"], target["workspace"]):
        raise ManagerError("Source and destination are the same.")


def move_windows(api, ctx, windows, target):
    """Sequential, explicitly non-transactional; never roll back or retry mutations."""
    validate_destination(api, ctx, target)
    moved, failures = [], []
    for window in windows:
        identity = window["window_id"]
        try:
            validate_destination(api, ctx, target)
            validate_window(api, ctx, identity)
            args = ["move-window", target["workspace"], "-s", ctx["session"], "-w", identity]
            if target["session"] != ctx["session"]:
                args += ["--to-session", target["session"]]
            api.run(*args)  # Never --follow here: follow once, after popup exits.
            moved.append(identity)
        except ManagerError as exc:
            failures.append(f"{plain(window.get('display_name') or identity)}: {exc}")
    return moved, failures


def check_client(api, ctx):
    source = session_by_id(api, ctx["session"])
    clients = api.run("list-clients")
    if not any(c["client_id"] == ctx["client"] and c.get("session") == source["name"] for c in clients):
        raise ManagerError("The invoking client changed sessions or disconnected; not stealing its focus.")


def apply_intent(api, ctx, intent):
    if not intent:
        return
    check_client(api, ctx)
    session_by_id(api, intent["session"])
    listing = api.windows(intent["session"])
    if not any(w["window_id"] == intent["window"] and w["workspace"] == intent["workspace"]
               for w in listing["windows"]):
        raise ManagerError("Target window changed location; not following stale selection.")
    api.run("focus-window", intent["window"], "-s", intent["session"])
    if intent["session"] != ctx["session"]:
        api.run("switch-session", intent["session"], "--client", ctx["client"])


class Picker:
    def __init__(self, directory):
        self.directory = Path(directory)

    def choose(self, entries, header, windows=False, preview=True):
        # Only generated opaque tokens cross the shell/template boundary.
        save(self.directory / "entries.json", entries)
        rows = "".join(f"{key}\t{entry['label']}\n" for key, entry in entries.items())
        (self.directory / "rows.tsv").write_text(rows, encoding="utf-8")
        env = dict(os.environ, TWM_STATE=str(self.directory), TWM_SCRIPT=str(ROOT / "window-manager.py"),
                   TWM_PYTHON=sys.executable)
        argv = ["tv", "tuios-windows" if windows else "tuios-destinations",
                "--config-file", str(TV_ROOT / "tuios-window-manager.toml"),
                "--cable-dir", str(TV_ROOT / "cable"), "--no-remote", "--no-sort",
                "--input-header", plain(header).replace("{", "(").replace("}", ")")]
        if windows:
            argv += ["--expect", "alt-m;alt-g;alt-f;ctrl-r"]
        if not preview:
            argv.append("--no-preview")
        # tv draws its UI on stderr. Forward it live while retaining a bounded
        # diagnostic tail; capture_output alone would hide the entire picker.
        process = subprocess.Popen(argv, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        diagnostic = bytearray()
        def forward():
            while chunk := process.stderr.read1(8192):
                diagnostic.extend(chunk)
                del diagnostic[:-65536]
                sys.stderr.buffer.write(chunk)
                sys.stderr.buffer.flush()
        reader = threading.Thread(target=forward, daemon=True)
        reader.start()
        output = process.stdout.read()
        process.wait()
        reader.join()
        process.stdout.close()
        process.stderr.close()
        error = diagnostic.decode("utf-8", errors="replace")
        if process.returncode:
            if process.returncode == 130:
                return "cancel", []
            raise ManagerError(f"Television exited {process.returncode}: {plain(error)}")
        lines = output.decode("utf-8").splitlines()
        # tv 0.15.9: only EXPECT keys add a key line; ordinary Enter emits
        # tokens directly. Esc/Ctrl+C may exit 0 with no output at all.
        if not lines:
            return "cancel", []
        key = "enter"
        if windows and lines[0] not in entries:
            key = lines.pop(0) or "enter"
        if key == "ctrl-r":
            return key, []
        if key not in ("enter", "alt-m", "alt-g", "alt-f"):
            raise ManagerError(f"Unexpected Television key: {plain(key)}")
        # Preserve source order and remove duplicates; reject unknown outputs.
        if any(line not in entries for line in lines):
            raise ManagerError("Television returned an unknown selection.")
        selected = set(lines)
        return key, [entries[k] for k in entries if k in selected]


def notice(message):
    print("\n" + plain(message, multiline=True), file=sys.stderr, flush=True)
    print("Press Enter to continue (Esc + Enter to exit).", file=sys.stderr, flush=True)
    return "\x1b" not in sys.stdin.readline()


def manage(api, ctx, directory, picker=None):
    picker = picker or Picker(directory)
    status = ""
    while True:
        windows = source_windows(api, ctx)
        entries = window_entries(windows, ctx)
        if not entries:
            notice(status + "\nSource workspace has no movable windows. Closing manager.")
            return
        header = f"Windows · {ctx['name']} / {ctx['workspace']} · Enter actions"
        if status:
            header = status + " | " + header
        key, selection = picker.choose(entries, header, windows=True)
        if key == "cancel":
            return
        if key == "ctrl-r" or not selection:
            continue
        selected = [entry["window"] for entry in selection]
        action = {"alt-m": "move", "alt-g": "follow", "alt-f": "focus"}.get(key)
        if action is None:
            actions = {"m0": {"label": "Move to…", "action": "move"},
                       "m1": {"label": "Move to… and follow", "action": "follow"}}
            if len(selected) == 1:
                actions["m2"] = {"label": "Focus window", "action": "focus"}
            _, picked = picker.choose(actions, f"Actions · {len(selected)} window(s)", preview=False)
            if not picked:
                continue
            if len(picked) != 1:
                notice("Choose just one action.")
                continue
            action = picked[0]["action"]
        try:
            if action == "focus":
                if len(selected) != 1:
                    status = "Focus requires a single window"
                    continue
                validate_window(api, ctx, selected[0]["window_id"])
                intent = {"session": ctx["session"], "workspace": ctx["workspace"],
                          "window": selected[0]["window_id"]}
            else:
                targets = destinations(api, ctx)
                _, picked = picker.choose(targets, f"{'Move and follow' if action == 'follow' else 'Move'} · {len(selected)} window(s) · Esc back")
                if not picked:
                    continue
                if len(picked) != 1:
                    notice("Choose just one destination.")
                    continue
                target = picked[0]
                if action == "follow":
                    check_client(api, ctx)
                moved, failures = move_windows(api, ctx, selected, target)
                status = f"Moved {len(moved)}/{len(selected)} → {target['name']} / {target['workspace']}"
                if failures:
                    if not notice(status + "\n" + "\n".join(failures) + "\nNo rollback; successful moves remain in place."):
                        return
                    continue
                if action != "follow":
                    continue
                intent = {"session": target["session"], "workspace": target["workspace"], "window": moved[0]}
            save(Path(directory) / "intent.json", intent)
            return  # Parent waits for popup to exit before focusing/switching.
        except ManagerError as exc:
            if not notice(str(exc)):
                return


def preview(token):
    if not TOKEN.fullmatch(token):
        raise ManagerError("Invalid preview token.")
    directory = Path(os.environ["TWM_STATE"])
    entry = load(directory / "entries.json")[token]
    ctx = load(directory / "context.json")
    api = Tuios()
    print(plain(entry["label"]))
    print("─" * 40)
    if "window" in entry:
        window = entry["window"]
        print(plain(window.get("title")))
        text = api.run("capture-pane", "-s", ctx["session"], "-w", window["window_id"],
                       "--scrollback", "--lines", "60", json_output=False)
        print(plain(text, multiline=True))
    elif "session" in entry:
        for window in api.windows(entry["session"])["windows"]:
            if window["workspace"] == entry["workspace"] and movable(window):
                print(plain(f"{window.get('index', '')}  {window.get('display_name') or window.get('title')}  ·  {window.get('cwd', '')}"))


def launch(api, args):
    ctx = context(api, args.session or os.environ.get("TUIOS_SESSION"), args.client)
    with tempfile.TemporaryDirectory(prefix="tuios-windows-") as directory:
        save(Path(directory) / "context.json", ctx)
        # --wait does not capture the popup's terminal output. Errors remain visible.
        api.run("popup", "-s", ctx["session"], "--workspace", ctx["workspace"], "--wait",
                "--width", "92%", "--height", "85%", "--name", "Window manager",
                "--", sys.executable, str(ROOT / "window-manager.py"), "--view", directory,
                json_output=False, timeout=None)
        intent_file = Path(directory) / "intent.json"
        if intent_file.exists():
            apply_intent(api, ctx, load(intent_file))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--session", help="Source session (default: TUIOS_SESSION)")
    parser.add_argument("--client", help="Client ID when several show the source session")
    parser.add_argument("--view", metavar="STATE_DIR", help=argparse.SUPPRESS)
    parser.add_argument("--preview", metavar="TOKEN", help=argparse.SUPPRESS)
    args = parser.parse_args()
    try:
        if args.preview:
            preview(args.preview)
        elif args.view:
            manage(Tuios(), load(Path(args.view) / "context.json"), args.view)
        else:
            for dependency in ("tuios", "tv", "bash"):
                if not shutil.which(dependency):
                    raise ManagerError(f"Missing executable: {dependency}")
            launch(Tuios(), args)
        return 0
    except (ManagerError, OSError, ValueError, KeyError) as exc:
        message = "window-manager: " + plain(str(exc))
        if args.view:
            notice(message)
        else:
            print(message, file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    sys.exit(main())
