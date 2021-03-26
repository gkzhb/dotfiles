#!/bin/bash
config="git --git-dir=$HOME/.dotfiles --work-tree=$HOME"
$config config --local status.showUntrackedFiles no
$config config --local core.worktree $HOME
$config config --unset core.bare
