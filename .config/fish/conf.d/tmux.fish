function ta --description='fzf select tmux session to attach'
  set raw_session (tmux list-sessions | fzf )
  if test $status = 0
    # fzf command succeeded, not canceled by user
    set session (echo $raw_session | sed 's/: .*$//')
    tmux attach-session -t $session
  end
end

# tmux aliases
alias t=tmux
alias tn='tmux new'
alias tsn='tmux display-message'
