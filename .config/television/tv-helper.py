#!/usr/bin/env python3
"""Safe argv-based commands for the custom Television channels (Python 3.9+)."""
import argparse
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys


class Error(Exception):
    pass


def run(argv, cwd=None, data=None):
    result = subprocess.run(argv, cwd=cwd, input=data, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)
    if result.returncode:
        raise Error(result.stderr.decode(errors='replace').strip() or f'{argv[0]} failed')
    return result.stdout


def git(*args, cwd=None):
    return run(['git', '--no-pager', '--literal-pathspecs', *args], cwd=cwd)


def clean(value):
    return ''.join(c if c.isprintable() else ' ' for c in str(value))


def token(value):
    return json.dumps(value, ensure_ascii=True).encode().hex()


def decode(value):
    if not re.fullmatch(r'[0-9a-f]{2,65536}', value):
        raise Error('Invalid selection token')
    try:
        return json.loads(bytes.fromhex(value))
    except (ValueError, UnicodeError) as exc:
        raise Error('Invalid selection token') from exc


def emit(value, label):
    print(token(value) + '\t' + clean(label))


def selected_path(value):
    value = decode(value)
    if not isinstance(value, str) or not os.path.isabs(value) or '\0' in value:
        raise Error('Invalid selected path')
    return value


def changed_selection(value):
    value = decode(value)
    if not isinstance(value, list) or len(value) != 2 or not all(isinstance(s, str) for s in value):
        raise Error('Invalid file selection')
    root, relative = value
    if (not os.path.isabs(root) or not relative or os.path.isabs(relative)
            or '..' in Path(relative).parts or '\0' in root + relative):
        raise Error('Invalid file selection')
    return root, relative


def changed_list():
    root = os.fsdecode(git('rev-parse', '--show-toplevel').removesuffix(b'\n'))
    paths = set()
    for args in [('diff', '--name-only', '-z'), ('diff', '--cached', '--name-only', '-z'),
                 ('ls-files', '--others', '--exclude-standard', '-z')]:
        paths.update(os.fsdecode(p) for p in git(*args, cwd=root).split(b'\0') if p)
    for relative in sorted(paths):
        emit([root, relative], relative)


def changed_preview(value):
    root, relative = changed_selection(value)
    data = git('status', '--short', '--', relative, cwd=root)
    data += git('diff', '--no-ext-diff', '--no-textconv', '--color=always', '--', relative, cwd=root)
    data += git('diff', '--cached', '--no-ext-diff', '--no-textconv', '--color=always', '--', relative, cwd=root)
    tracked = git('ls-files', '-z', '--', relative, cwd=root)
    path = Path(root) / relative
    if not tracked and path.is_file() and not path.is_symlink():
        with path.open('rb') as stream:
            content = stream.read(65536)
        data += b'\nUntracked file (first 64 KiB):\n'
        data += b'[binary file]\n' if b'\0' in content else content
    sys.stdout.buffer.write(data)


def confirm(message, word):
    # No stdin approval: a pipeline or tv output must never approve a mutation.
    try:
        with open('/dev/tty', 'w') as output, open('/dev/tty', 'r') as input_stream:
            output.write(message + f'\nType {word} to continue: ')
            output.flush()
            if input_stream.readline().strip() != word:
                raise Error('Cancelled')
    except OSError as exc:
        raise Error('An interactive terminal is required for confirmation') from exc


def editor(path):
    argv = shlex.split(os.environ.get('EDITOR') or 'nvim')
    if not argv:
        raise Error('EDITOR is empty')
    return subprocess.call([*argv, '--', path])


def changed_action(action, value):
    root, relative = changed_selection(value)
    path = os.path.join(root, relative)
    if action == 'restore':
        if not git('ls-files', '-z', '--', relative, cwd=root):
            raise Error('Cannot restore an untracked file')
        confirm(f'Discard unstaged changes to {clean(relative)}? This cannot be undone.', 'RESTORE')
        git('restore', '--worktree', '--', relative, cwd=root)
        return 0
    if action == 'edit':
        if not os.path.isfile(path):
            raise Error('Selected file no longer exists; refusing to create it')
        return editor(path)
    shell = os.environ.get('SHELL') or shutil.which('fish') or '/bin/sh'
    return subprocess.call([shell], cwd=os.path.dirname(path))


def worktree_list():
    fields = {}
    for field in git('worktree', 'list', '--porcelain', '-z').split(b'\0'):
        if not field:
            if 'worktree' in fields:
                path = fields['worktree']
                branch = fields.get('branch', '(detached ' + fields.get('HEAD', '')[:8] + ')')
                emit(path, branch.removeprefix('refs/heads/') + '  ' + path)
            fields = {}
            continue
        key, _, value = os.fsdecode(field).partition(' ')
        fields[key] = value


def worktree_preview(value):
    path = selected_path(value)
    print(clean(path), flush=True)
    sys.stdout.buffer.write(git('status', '--short', '--branch', cwd=path))
    sys.stdout.buffer.write(git('log', '--oneline', '--decorate', '--graph', '-10', '--color=always', cwd=path))


def commit_hash(value):
    if not re.fullmatch(r'[0-9a-f]{40}|[0-9a-f]{64}', value):
        raise Error('Invalid commit hash')
    return value


def log_list():
    # No raw subject/author content crosses into the shell command template.
    for row in git('log', '-n', '200', '--format=%H%x09%h %s (%an)').decode(errors='replace').splitlines():
        sha, _, label = row.partition('\t')
        print(commit_hash(sha) + '\t' + clean(label))


def log_action(action, value):
    sha = commit_hash(value)
    if action == 'preview':
        data = git('show', '--no-ext-diff', '--no-textconv', '--stat', '--patch',
                   '--pretty=fuller', '--color=always', sha, '--')
        sys.stdout.buffer.write(b'\n'.join(data.splitlines()[:1000]) + b'\n')
        return 0
    if action == 'copy':
        for executable, args in [('pbcopy', []), ('wl-copy', []), ('xclip', ['-selection', 'clipboard'])]:
            if shutil.which(executable):
                run([executable, *args], data=(sha + '\n').encode())
                return 0
        raise Error('No clipboard tool found (pbcopy, wl-copy or xclip)')
    if action == 'checkout':
        confirm(f'Checkout {sha[:12]} in detached HEAD mode?', 'CHECKOUT')
        return subprocess.call(['git', 'switch', '--detach', sha])
    confirm(f'Cherry-pick {sha[:12]} onto the current branch?', 'CHERRY-PICK')
    return subprocess.call(['git', 'cherry-pick', sha])


def service_target(value):
    label = selected_path_label(value)
    return f'gui/{os.getuid()}/{label}'


def selected_path_label(value):
    label = decode(value)
    if not isinstance(label, str) or not label or any(c in label for c in '/\0\n\r'):
        raise Error('Invalid service label')
    return label


def service_list():
    # Read exactly the GUI domain used by every subsequent action. launchctl's
    # print format is diagnostic, so fail closed if its services table changes.
    text = run(['launchctl', 'print', f'gui/{os.getuid()}']).decode(errors='replace')
    inside = False
    for line in text.splitlines():
        if line.strip() == 'services = {':
            inside = True
            continue
        if inside and line.strip() == '}':
            return
        if inside:
            fields = line.strip().split(None, 2)
            if len(fields) != 3 or not fields[0].isdigit():
                raise Error('Unrecognized launchctl services table')
            pid, status, label = fields
            emit(label, f'{label}  PID={pid} status={status}')
    raise Error('No complete GUI services table found')


def service_action(action, value):
    target = service_target(value)
    if action == 'preview':
        sys.stdout.buffer.write(run(['launchctl', 'print', target]))
        return 0
    if action == 'plist':
        text = run(['launchctl', 'print', target]).decode(errors='replace')
        match = re.search(r'^\s*path = (.+)$', text, re.MULTILINE)
        if not match or not os.path.isfile(match[1]):
            raise Error('No readable plist path found')
        if os.path.realpath(match[1]).startswith('/nix/store/'):
            raise Error('Nix-managed plist: edit the Nix configuration instead')
        return editor(match[1])
    descriptions = {'start': 'Start service', 'stop': 'Send SIGTERM (KeepAlive may restart it)',
                    'restart': 'Terminate and restart service', 'enable': 'Enable (does not start service)',
                    'disable': 'Disable (does not stop the running process)'}
    confirm(f'{descriptions[action]}: {clean(target)}?', action.upper())
    commands = {'start': ['kickstart', target], 'stop': ['kill', 'SIGTERM', target],
                'restart': ['kickstart', '-k', target], 'enable': ['enable', target],
                'disable': ['disable', target]}
    return subprocess.call(['launchctl', *commands[action]])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['changed-list', 'changed-preview', 'changed-edit',
        'changed-shell', 'changed-restore', 'worktree-list', 'worktree-preview', 'worktree-path',
        'log-list', 'log-preview', 'log-copy', 'log-checkout', 'log-cherry-pick',
        'service-list', 'service-preview', 'service-start', 'service-stop', 'service-restart',
        'service-enable', 'service-disable', 'service-plist'])
    parser.add_argument('token', nargs='?')
    args = parser.parse_args()
    try:
        if args.command.endswith('-list'):
            {'changed-list': changed_list, 'worktree-list': worktree_list,
             'log-list': log_list, 'service-list': service_list}[args.command]()
        elif args.token is None:
            raise Error('A selection token is required')
        elif args.command == 'changed-preview':
            changed_preview(args.token)
        elif args.command.startswith('changed-'):
            return changed_action(args.command[8:], args.token)
        elif args.command == 'worktree-preview':
            worktree_preview(args.token)
        elif args.command == 'worktree-path':
            # NUL-delimited output for Fish's string split0, including newlines.
            sys.stdout.buffer.write(os.fsencode(selected_path(args.token)) + b'\0')
        elif args.command.startswith('log-'):
            return log_action(args.command[4:], args.token)
        else:
            return service_action(args.command[8:], args.token)
        return 0
    except BrokenPipeError:
        raise
    except (Error, OSError, ValueError) as exc:
        print('tv-helper: ' + clean(exc), file=sys.stderr)
        return 1


if __name__ == '__main__':
    try:
        result = main()
        sys.stdout.flush()
    except BrokenPipeError:
        # The picker can close its source pipe after choosing an entry.
        os.dup2(os.open(os.devnull, os.O_WRONLY), sys.stdout.fileno())
        result = 0
    sys.exit(result)
