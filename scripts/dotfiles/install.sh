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

# neovim exists?
if hash nvim 2>/dev/null;
then
  # install vim-plug
	curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
