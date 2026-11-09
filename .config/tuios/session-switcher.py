#!/usr/bin/env python3
"""fzf session picker for tuios 0.10+: live pane directories and Git refs.

Default: open a popup from a tuios pane. --inline: use this terminal (also
for type="popup" keybindings). --list: read-only table, useful for diagnosis.
Requires python3, tuios, fzf and git. No attach, session creation or Git writes.
"""

import argparse
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
import unicodedata


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
        primary = primary or next((p for p in panes if p.get("focused") and p.get("cwd")), None)
        primary = primary or next((p for p in panes if p.get("cwd")), {})
        cwd = primary.get("cwd") or (session.get("worktree") or {}).get("path") or ""
        if cwd not in git_cache:
            git_cache[cwd] = git_info(cwd)
        repo, reason = git_cache[cwd]
        # Only fall back to daemon metadata when the real path cannot be read.
        ref = repo["ref"] if repo else "—"
        if not repo and reason != "not a repository":
            cached = session.get("branch") or (session.get("worktree") or {}).get("branch")
            if cached:
                ref = f"{cached} (cached)"
        directory = (Path(cwd).name or cwd) if cwd else session.get("dir") or "—"
        state = "current" if name == source else "attached" if session.get("attached") else "detached"
        fields = ["*" if name == source else " ", name, directory, ref, str(len(panes)), state]
        lines = [
            f"Session: {name}", f"Status: {state}", f"Directory: {cwd or 'unknown'}",
            f"Repository: {repo['root'] if repo else reason}",
            f"Git ref: {ref}", f"Commit: {repo['commit'] if repo else '—'}", "", "Panes:",
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
        records.append({"name": name, "fields": list(map(text, fields)), "preview": "\n".join(map(text, lines))})
    return records


def rows(records):
    header = ["", "SESSION", "DIRECTORY", "GIT BRANCH / COMMIT", "PANES", "STATUS"]
    widths = [max(len(record["fields"][i]) for record in records + [{"fields": header}]) for i in range(len(header))]

    def render(fields):
        return "  ".join(field.ljust(width) for field, width in zip(fields, widths)).rstrip()

    return render(header), [render(record["fields"]) for record in records]


def choose(records):
    header, display = rows(records)
    with tempfile.TemporaryDirectory(prefix="tuios-sessions-") as directory:
        snapshot = Path(directory) / "preview.json"
        snapshot.write_text(json.dumps([r["preview"] for r in records]), encoding="utf-8")
        snapshot.chmod(0o600)
        preview = " ".join(map(shlex.quote, [sys.executable, str(Path(__file__).resolve()), "--preview", str(snapshot)])) + " {1}"
        payload = b"\0".join(f"{i}\t{row}".encode() for i, row in enumerate(display)) + b"\0"
        env = dict(os.environ)
        # Options such as --expect/--multi or custom shell bindings would change
        # the output contract. This picker deliberately owns its fzf options.
        for key in ("FZF_DEFAULT_OPTS", "FZF_DEFAULT_OPTS_FILE", "FZF_DEFAULT_COMMAND"):
            env.pop(key, None)
        env["SHELL"] = shutil.which("sh") or "/bin/sh"
        result = subprocess.run(
            ["fzf", "--read0", "--print0", "--delimiter=\t", "--with-nth=2..",
             "--no-multi", "--no-sort", "--layout=reverse", "--border", "--prompt=Session> ",
             "--header=" + "Enter: switch · Esc/Ctrl-C: cancel · Ctrl-/: preview\n" + header,
             "--preview=" + preview, "--preview-window=down,45%,wrap", "--bind=ctrl-/:toggle-preview"],
            input=payload, stdout=subprocess.PIPE, env=env,
        )
    if result.returncode in (1, 130):
        return None
    if result.returncode:
        raise PickerError(f"fzf exited {result.returncode}")
    try:
        index = int(result.stdout.split(b"\t", 1)[0])
        if index < 0:
            raise ValueError()
        return records[index]["name"]
    except (ValueError, IndexError) as error:
        raise PickerError("Unexpected fzf selection") from error


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--inline", action="store_true", help="Run fzf in this terminal")
    mode.add_argument("--list", action="store_true", help="Print a read-only session table")
    parser.add_argument("--source", default=os.environ.get("TUIOS_SESSION", ""), help="Session whose client to switch")
    parser.add_argument("--active-pane", default=os.environ.get("TUIOS_ACTIVE_PANE_ID") or os.environ.get("TUIOS_WINDOW_ID", ""))
    parser.add_argument("--preview", nargs=2, metavar=("SNAPSHOT", "INDEX"), help=argparse.SUPPRESS)
    args = parser.parse_args(argv)
    if args.preview:
        path, index = args.preview
        print(json.loads(Path(path).read_text())[int(index)])
        return 0
    for dependency in ("tuios", "git") + (() if args.list else ("fzf",)):
        if not shutil.which(dependency):
            raise PickerError(f"Missing executable: {dependency}")
    if not args.inline and not args.list:
        if not args.source:
            raise PickerError("Run inside tuios, or use --inline in a terminal")
        return subprocess.call([
            "tuios", "popup", "-s", args.source, "--width", "95%", "--height", "85%", "--",
            sys.executable, str(Path(__file__).resolve()), "--inline", "--source", args.source,
            "--active-pane", args.active_pane,
        ])
    records = collect(args.source, args.active_pane)
    if not records:
        print("No live tuios sessions.", file=sys.stderr)
        return 0
    if args.list:
        header, display = rows(records)
        print("\n".join([header, *display]))
        return 0
    selected = choose(records)
    if selected is None or selected == args.source:
        return 0
    command = ["tuios", "switch-session"]
    if args.source:
        command += ["-s", args.source]
    # End flag parsing; pass the exact name, never the formatted display row.
    return subprocess.call([*command, "--", selected])


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (PickerError, OSError, subprocess.TimeoutExpired) as error:
        print(f"session-switcher: {error}", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        sys.exit(130)
