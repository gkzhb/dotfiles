#!/usr/bin/env python3
"""Reuse or create a local tuios session for an existing Git worktree (tvn)."""
import argparse
import json
import os
import re
import subprocess
import sys


class Error(Exception):
    pass


def run(*args, ok=(0,)):
    try:
        result = subprocess.run(args, capture_output=True, timeout=15)
    except subprocess.TimeoutExpired as exc:
        raise Error('Command timed out; inspect session state before retrying.') from exc
    if result.returncode not in ok:
        raise Error(os.fsdecode(result.stderr or result.stdout).strip() or
                    f'{args[0]} exited {result.returncode}')
    return result


def data(result):
    try:
        return json.loads(result.stdout)
    except (ValueError, UnicodeError) as exc:
        raise Error('Invalid JSON from tuios; no session created.') from exc


def canonical(value):
    if not isinstance(value, str) or not os.path.isabs(value) or '\0' in value:
        return None
    return os.path.realpath(value)


def git_root(path):
    if not canonical(path) or not os.path.isdir(path):
        return None
    result = run('git', '-C', path, 'rev-parse', '--show-toplevel', ok=(0, 128))
    if result.returncode:
        return None
    return canonical(os.fsdecode(result.stdout.removesuffix(b'\n')))


def validate_worktree(path):
    target = canonical(path)
    if not target or not os.path.isdir(target) or git_root(target) != target:
        raise Error('Selection is not an existing Git worktree root.')
    # Do not accept an arbitrary directory or create a Git worktree.
    listing = run('git', '-C', target, 'worktree', 'list', '--porcelain', '-z').stdout
    paths = [canonical(os.fsdecode(field[9:])) for field in listing.split(b'\0')
             if field.startswith(b'worktree ')]
    if target not in paths:
        raise Error('Selection is not a registered Git worktree.')
    return target


def list_sessions():
    result = run('tuios', 'ls', '--json', ok=(0, 3))
    sessions = data(result)
    if not isinstance(sessions, list) or any(
            not isinstance(row, dict) or not isinstance(row.get('name'), str)
            or not row['name'] or '\0' in row['name'] for row in sessions):
        raise Error('Invalid session listing; no session created.')
    # Stopped-daemon listings omit all directory/worktree facts. Refuse to
    # duplicate renamed saved sessions rather than guessing from their names.
    if sessions and (result.returncode == 3 or any(row.get('saved') for row in sessions)):
        raise Error('Daemon is stopped: use ta / tuios attach to restore saved sessions, then retry tvn.')
    return sessions


def matching_sessions(sessions, target):
    matches = []
    fallback = []
    for row in sessions:
        worktree = row.get('worktree')
        if worktree:
            if not isinstance(worktree, dict):
                raise Error('Invalid worktree metadata; no session created.')
            if canonical(worktree.get('path')) == target:
                matches.append(row)
        else:
            fallback.append(row)
    if fallback:
        listing = data(run('tuios', 'list-windows', '--all', '--json'))
        if not isinstance(listing, dict) or not isinstance(listing.get('panes'), list):
            raise Error('Invalid pane listing; no session created.')
        if listing.get('errors'):
            raise Error('Incomplete pane listing; resolve tuios read errors before retrying.')
        panes = listing['panes']
        if any(not isinstance(pane, dict) for pane in panes):
            raise Error('Invalid pane listing; no session created.')
        roots = {}
        for row in fallback:
            windows = row.get('windows') or []
            if not windows:
                continue
            if not isinstance(windows, list) or not isinstance(windows[0], dict):
                raise Error('Invalid window metadata; no session created.')
            first = windows[0].get('id')
            for pane in panes:
                # The first window is the session's project, as in tuios's
                # own grouping. A later/popup/remote pane must not bind it.
                if (pane.get('session') != row['name'] or not first
                        or pane.get('window_id') != first or pane.get('popup')
                        or pane.get('untrusted') or pane.get('host') not in (None, '', 'local')):
                    continue
                cwd = pane.get('cwd')
                if canonical(cwd):
                    if cwd not in roots:
                        roots[cwd] = git_root(cwd)
                    if roots[cwd] == target:
                        matches.append(row)
                break
    return matches


def switch_client():
    clients = data(run('tuios', 'list-clients', '--json'))
    if not isinstance(clients, list) or any(not isinstance(client, dict) for client in clients):
        raise Error('Invalid client listing; no session created.')
    source = os.environ.get('TUIOS_SESSION')
    candidates = [client for client in clients if not source or client.get('session') == source]
    if len(candidates) != 1 or not isinstance(candidates[0].get('client_id'), str):
        raise Error('Expected one attached source client; no session created.')
    return candidates[0]['client_id']


def create_session(target):
    # Let tuios choose its ordinary session-N identity, including on a cold
    # daemon. new --detach has no JSON flag; accept only its automatic-name
    # acknowledgement, never infer a target from an unrelated session listing.
    result = run('tuios', 'new', '--detach', '--cwd', target)
    created = re.search(r"^Created detached session '(session-[0-9]+)'\.",
                        os.fsdecode(result.stdout), re.MULTILINE)
    if not created:
        raise Error('Cannot read the newly created session identity; inspect tuios ls before retrying.')
    return created[1]


def open_worktree(path, switch):
    target = validate_worktree(path)
    sessions = list_sessions()
    matches = matching_sessions(sessions, target)
    # Prefer our own matching session, then the most recently used one.
    matches.sort(key=lambda row: (row['name'] == os.environ.get('TUIOS_SESSION'),
                                 row.get('last_active') or 0, row['name']), reverse=True)
    client = switch_client() if switch and not matches else None
    name = matches[0]['name'] if matches else create_session(target)
    if switch:
        params = {'name': name}
        if client:
            params['client'] = client
        # JSON name bypasses host/option parsing, including colons and quotes.
        run('tuios', 'call', 'switch-session', json.dumps(params))
    else:
        # local: keeps a custom name such as build:api on this machine.
        # Attach is interactive and intentionally has no subprocess timeout.
        return subprocess.call(['tuios', 'attach', '--', 'local:' + name])
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--switch', action='store_true')
    mode.add_argument('--attach', action='store_true')
    parser.add_argument('path')
    args = parser.parse_args()
    try:
        return open_worktree(args.path, args.switch)
    except (Error, OSError) as exc:
        message = ''.join(c if c.isprintable() else ' ' for c in str(exc))
        print('tvn: ' + message, file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
