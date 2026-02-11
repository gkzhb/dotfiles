#!/usr/bin/env fish
set -l win (aerospace list-windows --app-bundle-id com.github.wez.wezterm --monitor all)
if test -z "$win"
    wezterm start
else
    wezterm cli spawn --new-window
end
