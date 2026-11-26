#!/usr/bin/env python3
"""Open VS Code at the current tuios session's project root."""
import argparse
import json
import os
import subprocess
import sys


class Error(Exception):
    pass


def run(*args, env=None, ok=(0,)):
    try:
        result = subprocess.run(args, capture_output=True, env=env, timeout=15)
    except subprocess.TimeoutExpired as exc:
        raise Error(f'{args[0]} timed out; no automatic retry.') from exc
    if result.returncode not in ok:
        raise Error(os.fsdecode(result.stderr or result.stdout).strip() or
                    f'{args[0]} exited {result.returncode}')
    return result


def tuios_json(*args):
    try:
        value = json.loads(run('tuios', *args, '--json').stdout)
    except (ValueError, UnicodeError) as exc:
        raise Error('Invalid JSON from tuios.') from exc
    if isinstance(value, dict) and (value.get('errors') or value.get('error')
                                   or value.get('success') is False):
        raise Error('Cannot read tuios session metadata.')
    return value


def directory(value):
    if (not isinstance(value, str) or not os.path.isabs(value) or '\0' in value
            or not os.path.isdir(value)):
        raise Error('Project directory is missing or invalid.')
    return os.path.realpath(value)


def project_root(session):
    if not session:
        raise Error('Run inside tuios, or pass --session NAME.')
    sessions = tuios_json('ls')
    if not isinstance(sessions, list) or any(not isinstance(row, dict) for row in sessions):
        raise Error('Invalid session listing.')
    matches = [row for row in sessions if row.get('name') == session]
    if len(matches) != 1 or matches[0].get('saved'):
        raise Error('Current session is unavailable; not guessing another project.')
    source = matches[0]
    worktree = source.get('worktree')
    if worktree is not None:
        if not isinstance(worktree, dict) or worktree.get('gone'):
            raise Error('Session worktree is unavailable.')
        # A linked worktree is the project; repo_root is the main checkout.
        return directory(worktree.get('path'))

    windows = source.get('windows')
    if not isinstance(windows, list) or not windows or not isinstance(windows[0], dict):
        raise Error('Session has no project window.')
    first = windows[0].get('id')
    listing = tuios_json('list-windows', '--all')
    if not isinstance(listing, dict) or not isinstance(listing.get('panes'), list):
        raise Error('Invalid pane listing.')
    panes = listing['panes']
    if any(not isinstance(pane, dict) for pane in panes):
        raise Error('Invalid pane listing.')
    matches = [pane for pane in panes if first and pane.get('window_id') == first
               and pane.get('session') == session]
    if len(matches) != 1:
        raise Error('Session project window is unavailable.')
    pane = matches[0]
    if pane.get('popup') or pane.get('untrusted') or pane.get('host') not in (None, '', 'local'):
        raise Error('Project window is not a trusted local pane.')
    cwd = directory(pane.get('cwd'))
    # Caller Git overrides must not bind a different repository to this session.
    env = {key: value for key, value in os.environ.items() if not key.startswith('GIT_')}
    result = run('git', '-C', cwd, 'rev-parse', '--show-toplevel', env=env, ok=(0, 128))
    if result.returncode:
        return cwd  # Non-Git projects still open their session directory.
    return directory(os.fsdecode(result.stdout.removesuffix(b'\n')))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--session', default=os.environ.get('TUIOS_SESSION'))
    parser.add_argument('--print-root', action='store_true', help='Only print the directory; do not open VS Code')
    args = parser.parse_args()
    try:
        root = project_root(args.session)
        if args.print_root:
            print(root)
        else:
            # Never interpolate a session name or directory into a shell command.
            run('code', '--', root)
        return 0
    except (Error, OSError) as exc:
        message = ''.join(c if c.isprintable() else ' ' for c in str(exc))
        print('open-vscode: ' + message, file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
