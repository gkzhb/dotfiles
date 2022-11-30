# dotfiles

## Installation

You are suggested to folk this repo and clone the folked repo.

Use the following command to clone this repository(*replace the url with folked
repo's url*):

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

## Requirements

* [fish-shell](https://github.com/fish-shell/fish-shell) as my default shell

Dependencies required by Neovim plugins:

* [sharkdp/fd: A simple, fast and user-friendly alternative to 'find'](https://github.com/sharkdp/fd)
* [BurntSushi/ripgrep: ripgrep recursively searches directories for a regex pattern while respecting your gitignore](https://github.com/BurntSushi/ripgrep)
* [Git](https://github.com/git/git) to install [packer.nvim](https://github.com/wbthomason/packer.nvim)
* [nodejs/node: Node.js JavaScript runtime](https://github.com/nodejs/node) for coc.nvim

Suggested:

* [skywind3000/z.lua: A new cd command that helps you navigate faster by learning your habits.](https://github.com/skywind3000/z.lua)
  * Requires Lua
* [andreafrancia/trash-cli: Command line interface to the freedesktop.org trashcan.](https://github.com/andreafrancia/trash-cli): used in lf
* [junegunn/fzf: A command-line fuzzy finder](https://github.com/junegunn/fzf):
very useful cli tool to select item from a list
* **[gokcehan/lf: Terminal file manager](https://github.com/gokcehan/lf)**(highly
recommended): used in shell and also in Neovim
  * PS: [my `lfrc` config](./.config/lf/lfrc) is based on fish shell.
  * My lf config integrates with z.lua
    * `a` key to jump with z.lua and fzf
    * all navigations to directories will be recorded in z.lua's cd database so
    you can forget `cd` command and use `lc`(alias for `lfcd`) to navigate
    between directories

### Kitty

[Kitty](https://github.com/kovidgoyal/kitty) is a terminal. Use it on Mac OS and
Linux.  
[Config file](./.config/kitty/kitty.yml).

I use the onedark color theme as the color palette of my terminal.

### Alacritty

Alacritty is another terminal, simple and fast. I use it on Windows.  
[Config file](./.config/alacritty/alacritty.yml).

### tmux

See `.tmux.conf` and color theme file `.tmux/onedark.conf`. Use [tpm](https://github.com/tmux-plugins/tpm)
as plugin manager.

### Neovim

See [init.lua](./.config/nvim/init.lua). Use [packer.nvim](https://github.com/wbthomason/packer.nvim)
as plugin manager.

Use [OneDarkPro.nvim](https://github.com/olimorris/onedarkpro.nvim) color theme and
[coc.nvim](https://github.com/neoclide/coc.nvim) as the autocomplete tool which
is also LSP client. Also I add plenty of coc extensions in the config file.

### yabai & skhd (Mac OS only)

[koekeishiya/yabai: A tiling window manager for macOS based on binary space partitioning](https://github.com/koekeishiya/yabai): [yabairc](./yabairc)

[koekeishiya/skhd: Simple hotkey daemon for macOS](https://github.com/koekeishiya/skhd): [skhdrc](./skhdrc)

I made a swiftbar plugin [gkzhb/yabai-spaces](https://github.com/gkzhb/yabai-spaces) to display yabai spaces and manage space labels which I put at `$HOME/scripts/yabai-spaces`.

## More about this dotfiles repository

* [How to store dotfiles | Atlassian Git Tutorial](https://www.atlassian.com/git/tutorials/dotfiles)
* [使用裸 Git 仓库备份 \*nix 系统用户配置文件 - ZHB's Blog](https://blog.gkzhb.top/post/2021-3-dotfiles/)
