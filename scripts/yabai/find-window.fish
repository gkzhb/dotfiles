#!/usr/bin/env fish
set windows (yabai -m query --windows | jq '.[] | [.id, .app, .title] | @csv' | string split0)
set window_list
for win in $windows
  set -a window_list (string unescape -n $win)
end
set result (string join \n $window_list | choose -m)
set id (string split , $result)
yabai -m window --focus $id[1]
