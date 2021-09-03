#!/bin/sh

case "${1}" in
  next)
    step=1
    ;;
  prev)
    step=-1
    ;;
  *)
    echo >&2 "ERROR: must provide an argument 'next' or 'prev'!"
    exit 1
    ;;
esac

len=$(jq -nr --argjson displays "$(yabai -m query --displays)" \
  '$displays | length')
jq -nr \
  --argjson displays "$(yabai -m query --displays)" \
  --argjson focused "$(yabai -m query --displays --display)" \
  --argjson step "$step" \
  --argjson len "$len" \
  '$displays
    | sort_by(.frame.x)
    | .[index($focused) + if (index($focused) + $step) >= $len then (1 - $len) else $step end].index // $focused.index' \
    | xargs yabai -m display --focus
