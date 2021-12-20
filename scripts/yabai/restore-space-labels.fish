#!/usr/bin/env fish
set YABAI_LABEL_PATH "$HOME/.yabai-labels.csv"
if test -e "$YABAI_LABEL_PATH"
  set LABELS (cat $YABAI_LABEL_PATH)
  set label_list (string split \n $LABELS)
  for label_item in $label_list
    set label_kv (string split , $label_item)
    set index $label_kv[1]
    set label $label_kv[2]
    yabai -m space $index --label $label
  end
end
