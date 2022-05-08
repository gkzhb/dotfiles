# for Mac OS with terminal-notifier installed
if command -v terminal-notifier > /dev/null
  function send_notification
    set params -message $argv[1] -title Done
    terminal-notifier $params
  end
  alias sn=send_notification
end

# for Mac OS, use Quick Look from Finder.app
if command -v qlmanage > /dev/null
  function i -d 'preview file'
    echo a
    qlmanage -p $argv[1] >/dev/null 2>&1 &
  end
end
