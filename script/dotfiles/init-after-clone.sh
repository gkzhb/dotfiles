#!/bin/bash
git --git-dir=$HOME/.cfg --work-tree=$HOME config --local core.worktree $HOME
git --git-dir=$HOME/.cfg --work-tree=$HOME config --unset core.bare
