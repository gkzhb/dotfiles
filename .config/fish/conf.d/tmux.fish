function ta --description='fzf select tmux session to attach'
  set session (tmux list-sessions | fzf | sed 's/: .*$//')
  tmux attach-session -t $session
end

# tmux aliases
alias t=tmux
alias tn='tmux new'
alias tsn='tmux display-message'
