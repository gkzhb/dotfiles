require("zoxide"):setup {
	update_db = true,
}

require("relative-motions"):setup({ show_numbers="relative_absolute", show_motion = true, enter_mode ="first" })

require("githead"):setup({
  branch_color = "",
  branch_prefix = "on",
  branch_symbol = " ",
  branch_borders = "()",
  show_numbers = false,
  show_remote_branch = false,
  show_tag = false,
  show_commit = false,
  show_behind_ahead_remote = false,
  show_stashes = false,
  show_state = false,
  show_staged = false,
  show_unstaged = false,
  show_untracked = false,

  remote_branch_prefix = "@",
  remote_branch_color = "",

  tag_color = "",

  commit_color = "",

  ahead_remote_symbol = "+",
  ahead_remote_color = "",
  behind_remote_symbol = "-",
  behind_remote_color = "",

  stashes_symbol = "*",
  stashes_color = "",

  show_state_prefix = false,
  state_symbol = "~",
  state_color = "",

  staged_symbol = "S",
  staged_color = "",

  unstaged_symbol = "U",
  unstaged_color = "",

  untracked_symbol = "N",
  untracked_color = "",
})
