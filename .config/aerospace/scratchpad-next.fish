#!/usr/bin/env fish

# Get the currently focused workspace and the scratchpad window list for the current monitor.
# The scratchpad CLI supports structured output, so we read JSON and extract only the fields we need.
set current_workspace (aerospace list-workspaces --focused)
set scratchpad_lines (aerospace-scratchpad list -m current -o json)

# all_ids preserves the scratchpad iteration order returned by aerospace-scratchpad list.
# visible_ids tracks scratchpad windows that are currently shown in the focused workspace.
set all_ids
set visible_ids

# Build the ordered scratchpad window list and collect the subset that is visible right now.
for line in $scratchpad_lines
    set window_id (string match -rg '"window_id":([0-9]+)' -- $line)[1]
    set workspace (string match -rg '"workspace":"([^"]*)"' -- $line)[1]

    if test -z "$window_id"
        continue
    end

    set -a all_ids $window_id

    if test "$workspace" = "$current_workspace"
        set -a visible_ids $window_id
    end
end

# Nothing to rotate if the scratchpad is empty.
if test (count $all_ids) -eq 0
    exit 0
end

# Hide every scratchpad window currently shown in this workspace.
# The last visible one becomes the anchor that decides which window should be shown next.
set anchor_id ''
if test (count $visible_ids) -gt 0
    set anchor_id $visible_ids[-1]

    for window_id in $visible_ids
        set window_filter (string join '' 'window-id=^' $window_id '$')
        aerospace-scratchpad move . -F "$window_filter" >/dev/null 2>&1; or true
    end
end

# If we just hid a visible scratchpad window, show the window that comes after it.
# When the hidden window was already the last one in the ordered list, stop here and let
# the next invocation restart from the first scratchpad window.
# If nothing was visible before this invocation, start from the first window in the list.
set next_id ''
if test -n "$anchor_id"
    for index in (seq (count $all_ids))
        if test "$all_ids[$index]" = "$anchor_id"
            if test $index -lt (count $all_ids)
                set next_index (math "$index + 1")
                set next_id $all_ids[$next_index]
            end
            break
        end
    end
else
    set next_id $all_ids[1]
end

# If there is no next window to show, this invocation only hides the current one.
if test -z "$next_id"
    exit 0
end

# Show the selected scratchpad window by exact window-id match.
set next_filter (string join '' 'window-id=^' $next_id '$')
aerospace-scratchpad show . -F "$next_filter"

# After showing the next window, clamp its size so its bottom-right corner stays inside
# the current screen bounds. This is done via AppleScript because AeroSpace does not expose
# window geometry fields like x/y/width/height through its CLI.
set applescript_source '
tell application "Finder"
    set {screenLeft, screenTop, screenRight, screenBottom} to bounds of window of desktop
end tell

tell application "System Events"
    tell (first application process whose frontmost is true)
        tell front window
            set {windowLeft, windowTop} to position
            set {windowWidth, windowHeight} to size
            set maxWidth to screenRight - windowLeft
            set maxHeight to screenBottom - windowTop
            if maxWidth > 0 and maxHeight > 0 then
                set targetWidth to windowWidth
                set targetHeight to windowHeight
                if windowLeft + windowWidth > screenRight then
                    set targetWidth to maxWidth
                end if
                if windowTop + windowHeight > screenBottom then
                    set targetHeight to maxHeight
                end if
                if targetWidth is not equal to windowWidth or targetHeight is not equal to windowHeight then
                    set size to {targetWidth, targetHeight}
                end if
            end if
        end tell
    end tell
end tell
'
osascript -e "$applescript_source" >/dev/null 2>&1
