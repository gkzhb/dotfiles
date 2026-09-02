local M = {
  'samir-roy/code-bridge.nvim',
  opts = {
    tmux = {
      target_mode = 'find_process', -- 'window_name', 'current_window', 'find_process'
      window_name = 'pi', -- window name to search for when target_mode = 'window_name'
      process_name = 'pi', -- process name(s) to search for when target_mode = 'current_window' or 'find_process'
      switch_to_target = false, -- whether to switch to the target after sending
      find_node_process = true, -- whether to look for node processes with matching name
    },
  },
  lazy = false,
  keys = {
    { '<leader>ca', ':CodeBridgeTmux<CR>', desc = 'Send to Pi', mode = { 'n', 'v' } },
    { '<leader>ci', ':CodeBridgeTmuxInteractive<CR>', desc = 'Send to Pi interactively', mode = { 'n', 'v' } },
    { '<leader>cd', '<cmd>CodeBridgeTmuxDiff<CR>', desc = 'Send diff to Pi' },
    { '<leader>cr', ':CodeBridgeResumePrompt<CR>', desc = 'Resume chat input' },
  },
}
return M
