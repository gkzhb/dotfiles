# vim: set fdm=marker: 
# {{{1 environment

# set neovim as default editor
# and u can use `sudoedit` to edit file with root permissions while using ur nvim config
set -gx EDITOR nvim

# use vi key bindings in fish
fish_vi_key_bindings

# {{{1 functions
# set v2ray proxy
function vproxy
  set -gx all_proxy socks5://localhost:10880
  set -gx https_proxy http://localhost:10881
  set -gx http_proxy http://localhost:10881
end
function unvproxy
  set -e all_proxy
  set -e https_proxy
  set -e http_proxy
end

# remove path for current fish shell process
# from https://superuser.com/questions/776008/how-to-remove-a-path-from-path-variable-in-fish
function remove_path
  if set -l index (contains -i $argv[1] $PATH)
    # set --erase --universal fish_user_paths[$index]
    set --erase -g PATH[$index]
    echo "Updated PATH: $PATH"
  else
    echo "$argv[1] not found in PATH: $PATH"
  end
end

# {{{1 alias
# tmux aliases
alias t=tmux
alias tn='tmux new'
alias tsn='tmux display-message'
# systemd
alias s=systemctl

# {{{1 nvm
# set node download mirror
set -uU nvm_mirror http://npm.taobao.org/mirrors/node
# set node default version
# set -uU nvm_default_version v12

# {{{1 fzf
function fzf --wraps=fzf --description="Use fzf-tmux if in tmux session"
  if set --query TMUX
    fzf-tmux $argv
  else
    command fzf $argv
  end
end

# {{{1 z.lua
alias zz='z -c' # child path
alias zi='z -i' # interactive
alias zf='z -I' # fzf
alias zb='z -b' # cd ..
alias zh='z -I -t .'
function j
  cd $argv 2> /dev/null or zf $argv
end
complete -c j -k -w z
complete -c j -k -w cd
