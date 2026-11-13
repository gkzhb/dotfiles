#!/usr/bin/env python3
"""Television session picker: tuios repository groups first, live pane context second.

Default: open a popup from a tuios pane. --inline: use this terminal (also
for type="popup" keybindings). --list: read-only table, useful for diagnosis.
Requires python3, tuios, tv, bash and git. No attach, session creation or Git writes.
"""

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unicodedata

TV_ROOT = Path(__file__).resolve().parent.parent / "television"


class PickerError(Exception):
    pass


def text(value):
    """Never render terminal escapes, field separators or bidi controls."""
    return "".join(
        char if char.isprintable() and unicodedata.category(char) != "Cf" else " "
        for char in str(value or "")
    )


def tuios_json(*args):
    result = subprocess.run(
        ["tuios", *args, "--json"], capture_output=True, text=True, timeout=15
    )
    if result.returncode:
        raise PickerError(result.stderr.strip() or f"tuios exited {result.returncode}")
    try:
        data = json.loads(result.stdout)
    except ValueError as error:
        raise PickerError("Invalid JSON from tuios") from error
    if isinstance(data, dict) and data.get("success") is False:
        raise PickerError(text(data.get("error") or data.get("message")))
    return data


def git_info(cwd):
    if not cwd or not Path(cwd).is_dir():
        return None, "unavailable"
    # A caller inside a worktree must not impose its Git context on other panes.
    env = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}
    env["GIT_OPTIONAL_LOCKS"] = "0"

    def git(*args):
        result = subprocess.run(
            ["git", "-C", cwd, *args], capture_output=True, text=True,
            timeout=3, env=env,
        )
        return result.stdout.strip() if result.returncode == 0 else ""

    try:
        root = git("rev-parse", "--show-toplevel")
        if not root:
            return None, "not a repository"
        branch = git("symbolic-ref", "--quiet", "--short", "HEAD")
        commit = git("rev-parse", "--short=12", "HEAD")
        ref = branch or (f"{commit} (detached)" if commit else "unborn HEAD")
        return {"root": root, "ref": ref, "commit": commit}, ""
    except (OSError, subprocess.TimeoutExpired):
        return None, "Git unavailable"


def collect(source="", active_pane=""):
    sessions = tuios_json("ls")
    if not isinstance(sessions, list):
        raise PickerError("Expected session-list array")
    if not sessions:
        return []
    data = tuios_json("list-windows", "--all")
    if not isinstance(data, dict) or not isinstance(data.get("panes"), list):
        raise PickerError("Expected pane-list object")
    git_cache = {}
    records = []
    popup_id = os.environ.get("TUIOS_WINDOW_ID", "")
    for session in sorted(sessions, key=lambda s: s.get("last_active", 0), reverse=True):
        name = session.get("name")
        if not isinstance(name, str) or not name or session.get("saved"):
            continue
        panes = [p for p in data["panes"] if p.get("session") == name]
        # Popup focus should not replace the pane the key was invoked from.
        panes = [p for p in panes if p.get("window_id") != popup_id or popup_id == active_pane]
        primary = next((p for p in panes if name == source and p.get("window_id") == active_pane), None)
        primary = primary or next((p for p in panes if p.get("focused")), None)
        primary = primary or next((p for p in panes if p.get("cwd")), {})
        # Keep pane context separate: a worktree path is not this pane's CWD.
        cwd = primary.get("cwd") or ""
        if cwd not in git_cache:
            git_cache[cwd] = git_info(cwd)
        repo, reason = git_cache[cwd]
        directory = (Path(cwd).name or cwd) if cwd else "—"
        pane_repository = (Path(repo["root"]).name or repo["root"]) if repo else "—"
        pane_ref = repo["ref"] if repo else "—"
        worktree = session.get("worktree") or {}
        if worktree:
            # These are exactly the repository/branch used by tuios grouping.
            # Do not replace missing or stale group fields with another pane's
            # Git context: the pane may be in a completely different checkout.
            repository = worktree.get("repo") or "—"
            ref = worktree.get("branch") or "—"
            project_path = worktree.get("path") or "unknown"
            project_root = worktree.get("repo_root") or "unknown"
            project_source = "tuios worktree metadata"
        else:
            repository, ref = pane_repository, pane_ref
            project_path = project_root = repo["root"] if repo else "unknown"
            project_source = "selected pane Git" if repo else "unavailable"
            # Old daemons or unreadable paths can still offer a cached branch.
            # It belongs to the project fallback, never the live pane column.
            if not repo and reason != "not a repository" and session.get("branch"):
                ref = f"{session['branch']} (cached)"
                project_source = "daemon branch fallback"
        state = "current" if name == source else "attached" if session.get("attached") else "detached"
        fields = ["*" if name == source else " ", name, repository, ref, directory, pane_ref, str(len(panes)), state]
        lines = [
            f"Session: {name}", f"Status: {state}",
            f"Project source: {project_source}", f"Repository: {repository}",
            f"Project branch/ref: {ref}", f"Project directory: {project_path}",
            f"Repository root: {project_root}",
            f"Worktree directory gone: {bool(worktree.get('gone'))}", "",
            f"Selected pane: {primary.get('window_id') or 'unknown'}",
            f"Pane directory: {cwd or 'unknown'}",
            f"Pane repository: {repo['root'] if repo else reason}",
            f"Pane Git ref: {pane_ref}", f"Pane commit: {repo['commit'] if repo else '—'}",
            "", "Panes:",
        ]
        for pane in panes:
            pane_cwd = pane.get("cwd") or ""
            if pane_cwd not in git_cache:
                git_cache[pane_cwd] = git_info(pane_cwd)
            pane_repo, _ = git_cache[pane_cwd]
            pane_ref = f" [{pane_repo['ref']}]" if pane_repo else ""
            focus = "*" if pane is primary else " "
            lines.append(f" {focus} ws{pane.get('workspace', '?')}  {pane.get('command') or pane.get('title') or pane.get('name') or 'shell'}")
            lines.append(f"     {pane_cwd or 'unknown'}{pane_ref}")
        records.append({"name": name, "id": session.get("id"), "fields": list(map(text, fields)), "preview": "\n".join(map(text, lines))})
    return records


def display_width(value):
    return sum(
        0 if unicodedata.combining(c) else
        2 if unicodedata.east_asian_width(c) in ("W", "F") else 1
        for c in value
    )


def colors_enabled():
    return "NO_COLOR" not in os.environ and os.environ.get("TERM") != "dumb"


def color(value, style, enabled):
    return f"\x1b[{style}m{value}\x1b[0m" if enabled else value


def rows(records, colored=False):
    header = ["", "SESSION", "GIT REPOSITORY", "PROJECT BRANCH / REF", "PANE DIR", "PANE BRANCH / COMMIT", "PANES", "STATUS"]
    # Sanitize before adding our own ANSI; untrusted names never supply escapes.
    fields = [list(map(text, record["fields"])) for record in records]
    widths = [max(display_width(row[i]) for row in fields + [header]) for i in range(len(header))]

    def render(row, heading=False):
        styles = ["1;32", "1", "36", "35", "34", "33", "2", "2"]
        styles[-1] = {"current": "1;32", "attached": "32", "detached": "2"}.get(row[-1], "2")
        cells = []
        for i, field in enumerate(row):
            style = "1;36" if heading else "2" if field == "—" else styles[i]
            cells.append(color(field, style, colored) + " " * (widths[i] - display_width(field)))
        return "  ".join(cells).rstrip()

    return render(header, True), [render(row) for row in fields]


def television(labels, header, previews=None, expect_kill=False, colored=False):
    """Only snapshot tokens cross tv's shell/template and output boundaries."""
    with tempfile.TemporaryDirectory(prefix="tuios-sessions-") as directory:
        state = Path(directory)
        tokens = [f"s{i}" for i in range(len(labels))]
        (state / "rows.tsv").write_text(
            "".join(f"{token}\t{label}\n" for token, label in zip(tokens, labels)),
            encoding="utf-8",
        )
        snapshot = state / "preview.json"
        snapshot.write_text(json.dumps(previews or []), encoding="utf-8")
        snapshot.chmod(0o600)
        env = dict(os.environ, TS_STATE=directory, TS_PYTHON=sys.executable,
                   TS_SCRIPT=str(Path(__file__).resolve()))
        argv = ["tv", "tuios-sessions", "--config-file", str(TV_ROOT / "tuios-session-switcher.toml"),
                "--cable-dir", str(TV_ROOT / "cable"), "--no-remote", "--no-sort",
                "--input-header", text(header).replace("{", "(").replace("}", ")"),
                "--input-prompt", "Session> "]
        if colored:
            argv.append("--ansi")
        if expect_kill:
            argv += ["--expect", "ctrl-r"]
        if previews is None:
            argv.append("--no-preview")
        # tv renders to stderr; inherit it live, capture only selection tokens.
        result = subprocess.run(argv, stdout=subprocess.PIPE, env=env)
    if result.returncode == 130:
        return None
    if result.returncode:
        raise PickerError(f"Television exited {result.returncode}")
    try:
        parts = result.stdout.decode("utf-8").splitlines()
        if not parts:
            return None  # Esc / Ctrl+C can also exit 0 without a selection.
        action = "switch"
        if expect_kill and parts[0] == "ctrl-r":
            action = "kill"
            parts.pop(0)
        if len(parts) != 1 or parts[0] not in tokens:
            raise ValueError()
        return action, tokens.index(parts[0])
    except (ValueError, UnicodeError) as error:
        raise PickerError("Unexpected Television selection") from error


def choose(records, manual_input=False):
    colored = colors_enabled()
    _, display = rows(records, colored=colored)
    # Input headers are plain templates, not ANSI-aware result rows. Keep the
    # manual-mode hint short: tv truncates long titles from the left.
    header = "Multiple clients: press i in this UI to type" if manual_input else (
        "Enter: switch · Ctrl+R: kill (confirm) · Esc: cancel · Ctrl-/: preview | "
        + rows(records)[0]
    )
    selected = television(
        display, header,
        previews=[r["preview"] for r in records], expect_kill=True, colored=colored,
    )
    if selected is None:
        return None
    action, index = selected
    return action, records[index]


def live_kill_target(record, source):
    """Fail closed: deletion only reaches this exact still-live identity/name."""
    name, identity = record["name"], record.get("id")
    if not isinstance(identity, str) or not re.fullmatch(r"[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}", identity):
        raise PickerError("Cannot kill a session without a daemon UUID.")
    sessions = tuios_json("ls")
    if not isinstance(sessions, list):
        raise PickerError("Expected session-list array")
    targets = [s for s in sessions if s.get("id") == identity and s.get("name") == name and not s.get("saved")]
    if len(targets) != 1:
        raise PickerError("Session disappeared or was renamed/replaced; reopen the picker.")
    source_id = next((s.get("id") for s in sessions if s.get("name") == source), None)
    if name == source or identity == source_id:
        raise PickerError("Cannot kill the picker's own session; open it from another session.")
    return targets[0]


def confirm_kill(record):
    name = text(record["name"])
    selected = television(
        ["Cancel (keep session)", f"Kill session: {name}"],
        f"Confirm session kill · Terminate ALL windows/processes and disconnect clients: {name} · "
        "Cancel selected by default · Down then Enter: kill · Esc: cancel",
    )
    return selected is not None and selected[1] == 1


def kill_selected(record, source):
    live_kill_target(record, source)
    if not confirm_kill(record):
        return False
    # Confirming may take time; re-check identity, never kill a same-name replacement.
    live_kill_target(record, source)
    # JSON params keep hostile names literal (no shell or host/session parsing).
    tuios_json("call", "kill-session", json.dumps({"session": record["name"]}))
    return True


def enter_popup_terminal_mode(source):
    if not source:
        raise PickerError("Popup terminal mode requires --source SESSION.")
    # run-command selects an attached client, not a client UUID. With several
    # viewers skip only this convenience: the current UI can enter mode with i.
    clients = tuios_json("list-clients")
    if not isinstance(clients, list) or any(not isinstance(c, dict) for c in clients):
        raise PickerError("Expected client-list array")
    viewers = [c for c in clients if c.get("session") == source]
    if not viewers:
        raise PickerError("No client is showing the source session.")
    if len(viewers) > 1:
        return False
    tuios_json("call", "run-command", json.dumps({"session": source, "command": "TerminalMode"}))
    return True


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--inline", action="store_true", help="Run Television in this terminal")
    mode.add_argument("--list", action="store_true", help="Print a read-only session table")
    parser.add_argument("--terminal-mode", action="store_true", help="Enter terminal mode for this popup (requires --inline)")
    parser.add_argument("--source", default=os.environ.get("TUIOS_SESSION", ""), help="Session whose client to switch")
    parser.add_argument("--active-pane", default=os.environ.get("TUIOS_ACTIVE_PANE_ID") or os.environ.get("TUIOS_WINDOW_ID", ""))
    parser.add_argument("--preview", nargs=2, metavar=("SNAPSHOT", "TOKEN"), help=argparse.SUPPRESS)
    args = parser.parse_args(argv)
    if args.terminal_mode and (not args.inline or args.preview):
        raise PickerError("--terminal-mode requires --inline; --list remains read-only.")
    if args.preview:
        path, token = args.preview
        if not re.fullmatch(r"s[0-9]+", token):
            raise PickerError("Invalid preview token")
        previews = json.loads(Path(path).read_text(encoding="utf-8"))
        index = int(token[1:])
        if index >= len(previews):
            raise PickerError("Unknown preview token")
        print(previews[index])
        return 0
    for dependency in ("tuios", "git") + (() if args.list else ("tv", "bash")):
        if not shutil.which(dependency):
            raise PickerError(f"Missing executable: {dependency}")
    if not args.inline and not args.list:
        if not args.source:
            raise PickerError("Run inside tuios, or use --inline in a terminal")
        return subprocess.call([
            "tuios", "popup", "-s", args.source, "--width", "95%", "--height", "85%", "--",
            sys.executable, str(Path(__file__).resolve()), "--inline", "--terminal-mode", "--source", args.source,
            "--active-pane", args.active_pane,
        ])
    manual_input = False
    if args.terminal_mode:
        manual_input = not enter_popup_terminal_mode(args.source)
    while True:
        records = collect(args.source, args.active_pane)
        if not records:
            print("No live tuios sessions.", file=sys.stderr)
            return 0
        if args.list:
            header, display = rows(records)
            print("\n".join([header, *display]))
            return 0
        selected = choose(records, manual_input=manual_input)
        if selected is None:
            return 0
        action, record = selected
        if action == "kill":
            kill_selected(record, args.source)
            # Refresh after either cancellation or successful deletion. Errors
            # leave the picker, with no retry of an uncertain destructive call.
            continue
        name = record["name"]
        if name == args.source:
            return 0
        command = ["tuios", "switch-session"]
        if args.source:
            command += ["-s", args.source]
        return subprocess.call([*command, "--", name])


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (PickerError, OSError, subprocess.TimeoutExpired) as error:
        print(f"session-switcher: {error}", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        sys.exit(130)
