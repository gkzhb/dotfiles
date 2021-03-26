# dotfiles

Installation script is `script/install.sh`. It will install tpm and vim-plug for you.

## installation

You are suggested to folk this repo and clone the folked repo.

Use the following command to clone this repository(*replace the url with folked repo's url*):

```bash
git clone --bare https://gitee.com/gkzhb/dotfiles.git $HOME/.dotfiles
```

Set an alias temporary, and use `config` as git command

```bash
alias config=git --git-dir=$HOME/.dotfiles --work-tree=$HOME
```

Checkout the config files:

```bash
config checkout
```

And resolve conficts.

Finally, run two bash scripts: `script/dotfiles/install.sh` and `script/dotfiles/init-after-clone.sh`.

## kitty

[Kitty](https://github.com/kovidgoyal/kitty) is a terminal. The config file is `.config/kitty/kitty.yml`.

I use the [iceberg.vim](https://github.com/cocopon/iceberg.vim) color theme as the color palette of my terminal.

## alacritty

Alacritty is another terminal, simple and fast. Config file: `.config/alacritty/alacritty.yml`.

## tmux

See `.tmux.conf` and color theme file `.tmux/iceberg.conf`. Use [tpm](https://github.com/tmux-plugins/tpm) as plugin manager.

## neovim

See `.config/nvim/init.vim`. Use [Vim Plug](https://github.com/junegunn/vim-plug) as plugin manager.

Use [onedark](https://github.com/joshdick/onedark.vim) color theme and [coc.nvim](https://github.com/neoclide/coc.nvim) as auto implementation tool. Also I add plenty of coc extensions managed by vim-plug in the config file.
