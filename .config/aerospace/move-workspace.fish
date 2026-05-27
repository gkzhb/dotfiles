#!/usr/bin/env fish
set -l target_monitor (aerospace list-monitors --format '%{monitor-id} %{monitor-is-main}' --json | jq -r '.[] | select(."monitor-is-main" == false) | ."monitor-id"' | head -n 1)

if test -z "$target_monitor"
  echo "No secondary monitor found"
  exit 1
end

for ws in 6 7 8 9 10
  aerospace move-workspace-to-monitor --workspace $ws $target_monitor
end
