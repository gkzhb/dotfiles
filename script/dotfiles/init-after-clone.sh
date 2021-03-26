#!/bin/bash
git --git-dir=$HOME/.dotfiles --work-tree=$HOME config --local core.worktree $HOME
git --git-dir=$HOME/.dotfiles --work-tree=$HOME config --unset core.bare
