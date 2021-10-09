# dotfiles

## installation

You are suggested to folk this repo and clone the folked repo.

Use the following command to clone this repository(*replace the url with folked repo's url*):

```bash
git clone --bare https://github.com/gkzhb/dotfiles.git $HOME/.dotfiles
```

Set an alias temporary, and use `cfg` as git command

```bash
alias cfg='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
```

Checkout the config files:

```bash
cfg checkout
```

And resolve conflicts.

Finally, run two bash scripts: `script/dotfiles/install.sh` and `script/dotfiles/init-after-clone.sh`.

## kitty

[Kitty](https://github.com/kovidgoyal/kitty) is a terminal. The config file is `.config/kitty/kitty.yml`.

I use the onedark color theme as the color palette of my terminal.

## alacritty

Alacritty is another terminal, simple and fast. Config file: `.config/alacritty/alacritty.yml`.

## tmux

See `.tmux.conf` and color theme file `.tmux/onedark.conf`. Use [tpm](https://github.com/tmux-plugins/tpm) as plugin manager.

## neovim

See `.config/nvim/init.lua`. Use [packer.nvim](https://github.com/wbthomason/packer.nvim) as plugin manager.

Use [onedark.nvim](https://github.com/navarasu/onedark.nvim) color theme and [coc.nvim](https://github.com/neoclide/coc.nvim) as the autocomplete tool which is a lsp client. Also I add plenty of coc extensions in the config file.
