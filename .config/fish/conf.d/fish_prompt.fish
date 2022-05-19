# forked from https://github.com/oh-my-fish/theme-cbjohnson/blob/master/functions/fish_prompt.fish
function fish_prompt
  # Cache exit status
  set -l last_status $status

  # Just calculate these once, to save a few cycles when displaying the prompt
  if not set -q __fish_prompt_hostname
    set -g __fish_prompt_hostname (hostname|cut -d . -f 1)
  end
  if not set -q __fish_prompt_char
    switch (id -u)
      case 0
        set -g __fish_prompt_char \u276f\u276f
      case '*'
        set -g __fish_prompt_char »
    end
  end

  # Setup colors
  set -l normal (set_color normal)
  set -l cyan (set_color cyan)
  set -l yellow (set_color yellow)
  set -l bpurple (set_color -o purple)
  set -l bred (set_color -o red)
  set -l bcyan (set_color -o cyan)
  set -l bwhite (set_color -o white)
  set -l gray (set_color 555)

  # Configure __fish_git_prompt
  set -g __fish_git_prompt_show_informative_status true
  set -g __fish_git_prompt_showcolorhints true

  # Color prompt char red for non-zero exit status
  set -l pcolor $bpurple
  if test $last_status -ne 0
    set pcolor $bred
  end

  # Top
  echo -n $cyan$USER$normal at $yellow$__fish_prompt_hostname$normal in $bred(prompt_pwd)$normal
  __fish_git_prompt
  if test $last_status -ne 0
    echo -n ' '$pcolor'('$last_status')'
  end
  if test $CMD_DURATION -ne 0
    echo -n ' '$gray'('(__fish_prompt_get_duration)')'
  end

  echo $normal

  # Bottom
  echo -n $pcolor$__fish_prompt_char $normal
end

# from https://github.com/yeseni-today/ays-fish-theme/blob/master/fish_right_prompt.fish
function fish_right_prompt
  __lf_prompt
  __tmux_prompt
  set_color 666666
  printf ' [%s]' (date +%H:%M:%S)
  set_color normal
end


# show command execution duration, from https://github.com/rideron89/rider-theme/blob/master/fish_right_prompt.fish
function __fish_prompt_get_duration
  set -l seconds (math "$CMD_DURATION / 1000")
  set -l minutes (math "$seconds / 60")
  set -l hours (math "$minutes / 60")

  if test $hours -gt 0.1
    echo "$hours hrs"
  else if test $minutes -gt 1
    echo "$minutes mins"
  else if test $seconds -gt 0.1
    echo "$seconds s"
  else
    echo "$CMD_DURATION ms"
  end
end

function __tmux_prompt
  set multiplexer (_is_multiplexed)

  switch $multiplexer
    case screen
      set pane (_get_screen_window)
    case tmux
      set pane (_get_tmux_window)
   end

  set_color 666666
  if test -z $pane
    echo -n ""
  else
    echo -n $pane' |'
  end
end

function __lf_prompt
  set_color 666666
  if test -z $LF_LEVEL
    echo -n ''
  else
    echo -n 'lf: '$LF_LEVEL' |'
  end
end

function _get_tmux_window
  tmux lsw | grep active | sed 's/\*.*$//g;s/: / /1' | awk '{ print $2 "-" $1 }' -
end

function _get_screen_window
  set initial (screen -Q windows; screen -Q echo "")
  set middle (echo $initial | sed 's/  /\n/g' | grep '\*' | sed 's/\*\$ / /g')
  echo $middle | awk '{ print $2 "-" $1 }' -
end

function _is_multiplexed
  set multiplexer ""
  if test -z $TMUX
  else
    set multiplexer "tmux"
  end
  if test -z $WINDOW
  else
    set multiplexer "screen"
  end
  echo $multiplexer
end

