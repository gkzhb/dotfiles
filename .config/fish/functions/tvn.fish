function tvn --description 'Select a Git worktree and reuse or create its tuios session'
    argparse h/help -- $argv
    or return 2
    if set -q _flag_help
        printf '%s\n' \
            '用法: tvn [仓库目录]    用 Television 选择现有 Git worktree' \
            '按目录复用 tuios session，没有则创建；tuios 内切换，外部 attach。' \
            '默认当前仓库；取消不创建 session，也不改变当前 shell 目录。'
        return 0
    end
    if test (count $argv) -gt 1
        echo 'tvn: 最多接受一个仓库目录，请使用 tvn --help。' >&2
        return 2
    end
    for dependency in git tv python3 tuios
        if not command -q $dependency
            echo "tvn: 缺少命令 $dependency。" >&2
            return 1
        end
    end

    set -l repo "$PWD"
    if set -q argv[1]
        set repo "$argv[1]"
    end
    command git -C "$repo" rev-parse --git-dir >/dev/null
    or return 1
    set -l selection (command tv git-worktrees "$repo" --no-remote)
    set -l picker_status $status
    test $picker_status -eq 0; or return $picker_status
    test (count $selection) -gt 0; or return 0
    test (count $selection) -eq 1; or return 1
    test -n "$selection"; or return 0

    set -l destination (command python3 "$HOME/.config/television/tv-helper.py" worktree-path "$selection" | string split0)
    set -l decode_status $pipestatus[1]
    test $decode_status -eq 0; or return $decode_status
    if test (count $destination) -ne 1; or not test -d "$destination"
        echo 'tvn: 请选择一个存在的 worktree 目录。' >&2
        return 1
    end
    set -l mode --attach
    if set -q TUIOS_ENV; and test "$TUIOS_ENV" = 1
        set mode --switch
    end
    command python3 "$HOME/.config/tuios/worktree-session.py" $mode -- "$destination"
end
