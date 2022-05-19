#!/usr/bin/env fish

function check_requirements
  set -l ret 0
  set -l template_str 'Command "%s" not found.\n'
  if test -z (command -v curl)
    printf $template_str 'curl'
    set ret 1
  end
  if test -z (command -v wget)
    printf $template_str 'wget'
    set ret 1
  end
  if test -z (command -v jq)
    printf $template_str 'jq'
    set ret 1
  end
  return $ret
end

# get neovim appimage for linux
function get_neovim
  set -l prefix 'neovim: '
  echo $prefix'get latest version info...'
  set -l nvim_version (wget -q https://api.github.com/repos/neovim/neovim/releases/latest -O - | jq -r ".tag_name")
  set -l nvim_path (command -v nvim)
  set -l nvim_local_version ''
  if test -n $nvim_path
    # nvim exists
    set nvim_local_version (nvim -v)[1] # get first line
    set nvim_local_version (string split ' ' $nvim_local_version)[1]
  end
  if test $nvim_version != $nvim_local_version
    # latest neovim is not installed
    echo $prefix'latest version '$nvim_version', current version '$nvim_version
    wget -q https://github.com/neovim/neovim/releases/download/$nvim_version/nvim.appimage -O /tmp/nvim
    mv /tmp/nvim $nvim_path
    if test $status -ne 0
      sudo mv /tmp/nvim $nvim_path
    end
    if test $status -eq 0
      echo $prefix'update succeeds'
    else
      echo $prefix'update fails'
    end
  else
    echo neovim is latest $nvim_version
  end
end
