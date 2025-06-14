function fish_user_key_bindings
  fish_vi_key_bindings

  # Fix extra '\\I\\O' output when stopping running commands
  # Ref: https://github.com/fish-shell/fish-shell/issues/1917#issuecomment-72164812
  # bind \e\[I 'begin;end'
  # bind \e\[O 'begin;end'
end
