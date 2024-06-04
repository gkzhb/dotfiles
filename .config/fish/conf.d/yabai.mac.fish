if type -q yabai
  function resize_window --description='resize yabai managed window'
    set -l target_width $argv[1]
    set -l width (yabai -m query --windows --window | jq '.frame.w')
    set -l delta_width (math $target_width - $width)
    set -l opposite_delta_width (math - $delta_width)
    yabai -m window --resize "left:$opposite_delta_width:0"; or yabai -m window --resize "right:$delta_width:0"
  end
  if type -q open
    function refresh_swiftbar --description='refresh swiftbar component'
      open -gj "swiftbar://refreshplugin?name=$argv[1]"
    end
  end
end

