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
  if test -z "$VPROXY_HOST"
    set -gx VPROXY_HOST localhost
  end
  set -gx all_proxy socks5://$VPROXY_HOST:10880
  set -gx https_proxy http://$VPROXY_HOST:10881
  set -gx http_proxy http://$VPROXY_HOST:10881
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

function mkfile --description="Create file and its directory path"
  set -l file $argv[1]
  mkdir -p (dirname $file) && touch $file
end

function mk --description="Create file or directory"
  set -l file $argv[1]
  if string match -r \/\$ $file
    # create directories only
    mkdir -p $file
  else
    mkfile $file
  end
end

# {{{1 nvm
# set node download mirror
set -uU nvm_mirror https://npmmirror.com/mirrors/node/
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
