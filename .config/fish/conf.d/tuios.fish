function ta --description='fzf select tuios session to attach or switch'
  for dependency in tuios jq fzf
    if not command -q $dependency
      echo "ta: 缺少命令 $dependency。" >&2
      return 1
    end
  end

  set -l sessions_json (command tuios ls --json)
  set -l list_status $status
  # Exit 3 lists saved sessions when the daemon is stopped; attach restores them.
  if test $list_status -ne 0; and test $list_status -ne 3
    return $list_status
  end
  # Worktree sessions expose a full path; other sessions expose tuios's directory label.
  set -l sessions (printf '%s\n' $sessions_json | command jq -r '
    .[] | [
      .name,
      (.worktree.path // .dir // "-"),
      (.window_count // 0 | tostring),
      (if .saved then "saved" elif .attached then "attached" else "detached" end)
    ] | @tsv
  ')
  or return 1
  if not set -q sessions[1]
    echo 'ta: 当前没有 tuios session，请用 tn 创建。' >&2
    return 1
  end

  set -l selection (printf '%s\n' $sessions | command fzf \
    --delimiter=\t --tabstop=24 \
    --header=(printf 'SESSION NAME\tDIRECTORY\tWINDOWS\tSTATUS') \
    --prompt='选择 tuios session > ')
  set -l picker_status $status
  test $picker_status -eq 0; or return $picker_status
  test -n "$selection"; or return 0
  # Only the first field is the session target; keep spaces in names intact.
  set -l session (string split -m 1 -- \t "$selection")[1]

  if set -q TUIOS_ENV; and test "$TUIOS_ENV" = 1
    command tuios switch-session "$session"
  else
    command tuios attach "$session"
  end
end
