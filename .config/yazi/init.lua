require("zoxide"):setup {
	update_db = true,
}

require("relative-motions"):setup({ show_numbers="relative_absolute", show_motion = true, enter_mode ="first" })

require("githead"):setup({
  branch_prefix = "on",
  branch_symbol = " ",
  branch_borders = "()",
})
