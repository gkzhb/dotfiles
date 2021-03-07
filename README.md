# dotfiles

Installation script is `script/install.sh`. It will install tpm and vim-plug for you.

## color palette

From dark theme of [iceberg.vim](https://github.com/cocopon/iceberg.vim):

```
color0 #1e2132
color8 #6b7089

# black

color1 #e27878
color9 #e98989

# red

color2 #b4be82
color10 #c0ca8e

# green

color3 #e2a478
color11 #e9b189

# yellow

color4 #84a0c6
color12 #91acd1

# blue

color5 #a093c7
color13 #ada0d3

# magenta

color6 #89b8c2
color14 #95c4ce

# cyan

color7 #c6c8d1
color15 #d2d4de

# white
```

## kitty

[Kitty](https://github.com/kovidgoyal/kitty) is a terminal. The config file is `.config/kitty/kitty.yml`.

I use the [iceberg.vim](https://github.com/cocopon/iceberg.vim) color theme as the color palette of my terminal.

## tmux

See `.tmux.conf` and color theme file `.tmux/iceberg.conf`. Use [tpm](https://github.com/tmux-plugins/tpm) as plugin manager.

## neovim

See `.config/nvim/init.vim`. Use [Vim Plug](https://github.com/junegunn/vim-plug) as plugin manager.

Use [iceberg.vim](https://github.com/cocopon/iceberg.vim) color theme and [coc.nvim](https://github.com/neoclide/coc.nvim) as auto implementation tool. Also I add plenty of coc extensions managed by vim-plug in the config file.
