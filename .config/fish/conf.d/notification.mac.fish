# for Mac OS with terminal-notifier installed
if command -v terminal-notifier > /dev/null
  function send_notification
    set params -message $argv[1] -title Done
    terminal-notifier $params
  end
  alias sn=send_notification
end

