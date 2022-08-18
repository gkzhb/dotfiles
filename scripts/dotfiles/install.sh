#!/bin/bash

dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
cd "$dir"

# tmux exists?
if hash tmux 2>/dev/null;
then
  # install tpm
  mkdir -p ~/.tmux/plugins
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  tmux source ~/.tmux.conf
fi

if hash fish 2>/dev/null;
then
  # install fisher and its plugins
  curl -sL https://git.io/fisher | source && fisher install "$(cat $HOME/.config/fish/fish_plugins)"
fi
