if type -q emacsclient
  function ec --description='emacsclient (start new emacs instance if it is not exists)'
    emacsclient -n -c -a ''
  end
  function ecnw --description='emacsclient with terminal (start new emacs instance if it is not exists)'
    emacsclient -nw -a ''
  end
end
