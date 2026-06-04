# set claude code model
function set_cc_model
  set -gx ANTHROPIC_DEFAULT_OPUS_MODEL $argv[1]
  set -gx ANTHROPIC_DEFAULT_SONNET_MODEL $argv[1]
  # set -gx ANTHROPIC_DEFAULT_HAIKU_MODEL $argv[1]
end
set -gx ANTHROPIC_DEFAULT_HAIKU_MODEL MiniMax-M3
set_cc_model MiniMax-M3
alias cyolo='claude --dangerously-skip-permissions'
