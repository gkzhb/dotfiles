#!/usr/bin/env fish
# Lazy, shared Pi for tuios. Requires fish, tuios, jq and pi.
#
# Shell:     fish ~/.config/tuios/pi-popup.fish
# Popup key: command = "fish ~/.config/tuios/pi-popup.fish --view"
#            type = "popup"
#
# Settings (export before invoking, or set with env in the keybinding):
#   PI_POPUP_SESSION   Dedicated tuios session (default: pi-assistant)
#   PI_POPUP_WINDOW    Dedicated window name (default: pi)
#   PI_POPUP_CWD       Startup directory (default: $HOME/.config/tuios)
#   PI_POPUP_BIN       Pi executable (default: pi)
# Arguments after -- are passed to Pi ONLY when starting a new process.
# Closing the popup leaves Pi running. Ctrl+C/Esc go to Pi, NOT to this script.
# Process/daemon restarts start a NEW conversation; no automatic --continue.

function _pi_popup_error
    printf 'pi-popup: %s\n' "$argv" >&2
end

argparse h/help view ensure-only -- $argv
or exit 2
if set -q _flag_help
    printf '%s\n' \
        'Usage: pi-popup.fish [--view | --ensure-only] [-- PI_ARGS...]' \
        '  default        Open a popup in the calling tuios session.' \
        '  --view         Ensure Pi exists, then view it in this terminal.' \
        '                 Use this mode with a type="popup" keybinding.' \
        '  --ensure-only  Ensure Pi exists and print its window id; do not view.' \
        '  Settings: PI_POPUP_SESSION, PI_POPUP_WINDOW, PI_POPUP_CWD, PI_POPUP_BIN.'
    exit 0
end
if set -q _flag_view; and set -q _flag_ensure_only
    _pi_popup_error '--view and --ensure-only are mutually exclusive'
    exit 2
end

for dependency in tuios jq
    if not command -sq $dependency
        _pi_popup_error "Missing executable: $dependency"
        exit 127
    end
end

# Default invocation creates the overlay. The child performs lazy initialization.
if not set -q _flag_view; and not set -q _flag_ensure_only
    if not set -q TUIOS_SESSION; or test -z "$TUIOS_SESSION"
        _pi_popup_error 'Run inside tuios, or use --view to show Pi in this terminal.'
        exit 2
    end
    exec tuios popup -s "$TUIOS_SESSION" --width 85% --height 80% -- \
        (status fish-path) (status filename) --view -- $argv
end

set -l target_session pi-assistant
set -l target_window pi
set -l target_cwd "$HOME/.config/tuios"
set -l pi_bin pi
set -q PI_POPUP_SESSION; and set target_session "$PI_POPUP_SESSION"
set -q PI_POPUP_WINDOW; and set target_window "$PI_POPUP_WINDOW"
set -q PI_POPUP_CWD; and set target_cwd "$PI_POPUP_CWD"
set -q PI_POPUP_BIN; and set pi_bin "$PI_POPUP_BIN"
if test -z "$target_session"; or test -z "$target_window"
    _pi_popup_error 'Session and window names must not be empty.'
    exit 2
end

# Atomic mkdir prevents two concurrent invocations starting two Pi processes.
# No polling: a concurrent caller can retry after initialization finishes.
# A hard kill may leave a stale lock: remove the EMPTY directory named in the
# error only after checking that no initializer is still running.
set -l lock_key (printf '%s\n' "$TUIOS_SOCKET" "$TUIOS_SERVER" "$target_session" | cksum | string split ' ')[1]
set -l temp_root /tmp
if set -q TMPDIR; and test -n "$TMPDIR"
    set temp_root "$TMPDIR"
end
set -g _pi_popup_lock "$temp_root/tuios-pi-popup-"(id -u)"-$lock_key.lock"
umask 077
if not mkdir -- "$_pi_popup_lock" 2>/dev/null
    _pi_popup_error "Initialization is busy (or a stale lock exists): $_pi_popup_lock"
    exit 1
end
function _pi_popup_cleanup --on-event fish_exit
    rmdir -- "$_pi_popup_lock" 2>/dev/null
end
function _pi_popup_interrupted --on-signal INT --on-signal TERM
    exit 130
end

# Do not mistake transport/permission failures for a missing session.
set -l sessions (tuios ls --json | string collect)
set -l list_status $pipestatus[1]
if test "$list_status" -ne 0
    _pi_popup_error "Cannot list live sessions (tuios exit $list_status)."
    exit "$list_status"
end
set -l exists (printf '%s' "$sessions" | jq -er --arg s "$target_session" 'if type == "array" then any(.[]; .name == $s) else error("expected sessions array") end')
set -l json_status $pipestatus[2]
if test "$json_status" -gt 1
    _pi_popup_error 'Invalid session-list JSON.'
    exit 1
end

set -l pane_id
if test "$exists" = true
    set -l windows (tuios list-windows -s "$target_session" --json | string collect)
    set -l windows_status $pipestatus[1]
    if test "$windows_status" -ne 0
        exit "$windows_status"
    end
    # display_name is the explicit window name, ahead of the program's title.
    set -l matches (printf '%s' "$windows" | jq -cer --arg w "$target_window" \
        '[.windows[] | select(.display_name == $w)]')
    or exit 1
    set -l count (printf '%s' "$matches" | jq length)
    if test "$count" -gt 1
        _pi_popup_error "More than one window named $target_window; refusing to guess."
        exit 1
    else if test "$count" -eq 1
        # A restored shell is not the old Pi. Never type a startup command into it.
        if printf '%s' "$matches" | jq -e '.[0].at_prompt == true' >/dev/null
            _pi_popup_error 'The Pi window is now at a shell prompt (possibly restored). Close or rename that window, then retry.'
            exit 1
        end
        set pane_id (printf '%s' "$matches" | jq -er '.[0].window_id')
        or exit 1
        # Detached sessions retain exited windows and their last screen. A name
        # (or stale pid) is not proof that Pi is alive. Probe via the daemon.
        set -l probe_params (jq -cn --arg s "$target_session" --arg w "$pane_id" \
            '{session:$s, window:$w, condition:"window-exit", timeout:1}')
        or exit 1
        set -l probe (tuios call wait-for "$probe_params" | string collect)
        set -l probe_status $pipestatus[1]
        if test "$probe_status" -eq 0
            if not printf '%s' "$probe" | jq -e '.matched == true and .condition == "window-exit"' >/dev/null
                _pi_popup_error "Unexpected exit-status response: $probe"
                exit 1
            end
            # Only remove a pane whose process the daemon confirms has exited.
            tuios close-window -s "$target_session" "$pane_id" >/dev/null
            or exit $status
            set pane_id
        else if not printf '%s' "$probe" | jq -e '.error.code == "timeout"' >/dev/null
            # Permission/transport failures must never be treated as an exit.
            _pi_popup_error "$probe"
            exit 1
        end
    end
end

if test -z "$pane_id"
    if not test -d "$target_cwd"
        _pi_popup_error "Startup directory does not exist: $target_cwd"
        exit 2
    end
    set -l pi_path (command -s -- "$pi_bin")
    if test -z "$pi_path"
        _pi_popup_error "Missing Pi executable: $pi_bin"
        exit 127
    end
    if test "$exists" = false
        # One atomic call: create the session with Pi as its first process.
        set -l params (jq -cn --arg s "$target_session" --arg w "$target_window" \
            --arg cwd "$target_cwd" --arg bin "$pi_path" --args \
            '{name:$s, window_name:$w, cwd:$cwd, command:([$bin] + $ARGS.positional)}' -- $argv)
        or exit 1
        set -l result (tuios call new-session "$params" | string collect)
        set -l create_status $pipestatus[1]
        if test "$create_status" -ne 0
            _pi_popup_error "$result"
            exit "$create_status"
        end
        # Read back the authoritative window id, independent of call's result shape.
        set -l windows (tuios list-windows -s "$target_session" --json | string collect)
        set -l windows_status $pipestatus[1]
        if test "$windows_status" -ne 0
            exit "$windows_status"
        end
        set pane_id (printf '%s' "$windows" | jq -er --arg w "$target_window" \
            '.windows[] | select(.display_name == $w) | .window_id')
        or exit 1
    else
        set pane_id (tuios new-window -s "$target_session" "$target_window" \
            --cwd "$target_cwd" --no-focus --print-id -- "$pi_path" $argv)
        or exit $status
    end
end

# Release before exec: fish_exit handlers do not run when exec replaces fish.
rmdir -- "$_pi_popup_lock"
or exit 1
functions -e _pi_popup_cleanup _pi_popup_interrupted
if set -q _flag_ensure_only
    printf '%s\n' "$pane_id"
    exit 0
end
exec tuios pane-view -s "$target_session" -w "$pane_id"
