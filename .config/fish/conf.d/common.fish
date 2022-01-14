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

# {{{1 alias
# tmux aliases
alias t=tmux
alias tn='tmux new'
# {{{1 nvm
# set node download mirror
set -uU nvm_mirror http://npm.taobao.org/mirrors/node
# set node default version
set -uU nvm_default_version v12
