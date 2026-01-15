local M = {
  'samir-roy/code-bridge.nvim',
  opts = {
    tmux = {
      target_mode = 'find_process', -- 'window_name', 'current_window', 'find_process'
      window_name = 'coco', -- window name to search for when target_mode = 'window_name'
      process_name = 'coco', -- process name(s) to search for when target_mode = 'current_window' or 'find_process'
      switch_to_target = true, -- whether to switch to the target after sending
      find_node_process = false, -- whether to look for node processes with matching name
    },
  },
  keys = {
    { '<leader>ca', '<cmd>CodeBridgeTmux<CR>', desc = 'Send to Coco' },
    { '<leader>ci', '<cmd>CodeBridgeTmuxInteractive<CR>', desc = 'Send to Coco' },
    { '<leader>cd', '<cmd>CodeBridgeTmuxDiff<CR>', desc = 'Send diff to Coco' },
  },
}
return M
