#!/bin/bash

# Used by yabai and skhd
# Open kitty window in the current display instead of the display where the
# first kitty window was created.
index=$(yabai -m query --displays --display | jq .index)
yabai -m signal --add event=window_created action=" \
  yabai -m signal --remove 'testkitty' &&
  yabai -m window $YABAI_WINDOW_ID --display $index &&
  yabai -m display --focus $index" \
app="kitty" label="testkitty"
kitty --single-instance --instance-group=1 -d ~
