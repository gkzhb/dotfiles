#!/usr/bin/env fish
# set label for current space
function rename_space
  if test -z "$argv" ; or test "$argv" = '»'
    # clear space label
    yabai -m space --label ''
  else
    # set new label
    yabai -m space --label "$argv"
  end
end
rename_space (echo '»' | choose -m)
