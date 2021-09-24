# vim: set fdm=marker: 
# {{{1 environment

# set neovim as default editor
# and u can use `sudoedit` to edit file with root permissions while using ur nvim config
set -gx EDITOR nvim

# use vi key bindings in fish
fish_vi_key_bindings

# {{{1 alias
# set v2ray proxy
alias vproxy="set -gx all_proxy socks5://localhost:10880"
alias unvproxy="set -e all_proxy"
