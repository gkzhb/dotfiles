if status is-login
  # tmux aliases
  alias t=tmux
  alias tn='tmux new'
  alias tsn='tmux display-message'

  alias oc=opencode
  # edit opencode configs
  alias occ='cd ~/.config/opencode; opencode'

  # lf @deprecated
  alias lc=lfcd

  # systemd
  if type -q systemctl
    alias s="sudo systemctl"
    alias us="systemctl --user"
  end
  alias g=git
  alias v=nvim
  
  # npm registry
  alias npmjs='npm --registry https://registry.npmjs.org/'
  alias cnpm='npm --registry https://registry.npmmirror.com/'
  

  # dotfiles
  alias cfg='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
  alias dv='env GIT_DIR=$HOME/.dotfiles nvim'

  if type -q zoxide
    zoxide init fish | source
    set -gx _ZO_ECHO 1
    alias zz="z \$PWD"
  end

  if type -q bun
    fish_add_path $HOME/.bun/bin/
  end

  if type -q go
    fish_add_path $HOME/go/bin/
  end

  if type -q nvim
    alias vi='nvim -u NORC'
  end

end
