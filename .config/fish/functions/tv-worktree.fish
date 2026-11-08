function tv-worktree --description 'Select a Git worktree and cd in the current shell'
    set -l selection (command tv git-worktrees --no-remote)
    or return
    if test (count $selection) -ne 1
        return 1
    end
    set -l destination (command python3 "$HOME/.config/television/tv-helper.py" worktree-path "$selection" | string split0)
    if test (count $destination) -ne 1; or not test -d "$destination"
        return 1
    end
    cd -- "$destination"
end
