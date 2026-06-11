set -gx PNPM_HOME "$HOME/.local/share/pnpm"

if test (uname) = Darwin
  set -l PNPM_BIN_PATH $PNPM_HOME
else
  set -l PNPM_BIN_PATH $PNPM_HOME/bin
end
if not string match -q -- $PNPM_BIN_PATH $PATH
  fish_add_path $PNPM_BIN_PATH
end
