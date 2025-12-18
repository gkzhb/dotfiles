local M = {
  'NickvanDyke/opencode.nvim',
  dependencies = {
    'numToStr/Navigator.nvim',
    'folke/snacks.nvim',
  },
}

-- util function below are from opencode.nvim
local function is_buf_valid(buf)
  return vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_get_option_value('buftype', { buf = buf }) == ''
end

-- Check if coc.nvim is available and ready
local function is_coc_available()
  return vim.fn.exists('*CocAction') == 1 and vim.fn['coc#rpc#ready']()
end

-- Safely get coc diagnostics
local function get_coc_diagnostics_safely()
  if not is_coc_available() then
    return nil
  end

  local success, result = pcall(vim.fn.CocAction, 'diagnosticList')
  if not success then
    return nil
  end

  return result or {}
end

-- Format diagnostic message
local function format_diagnostic_message(diagnostic, file_path)
  local start_line = diagnostic.lnum + 1
  local start_col = diagnostic.col + 1
  local end_line = diagnostic.endLnum and diagnostic.endLnum + 1 or start_line
  local end_col = diagnostic.endCol and diagnostic.endCol + 1 or start_col
  local short_message = diagnostic.message:gsub('%s+', ' '):gsub('^%s', ''):gsub('%s$', '')

  return string.format(
    '%s:L%d:C%d-L%d:C%d: (%s) %s',
    file_path or diagnostic.file,
    start_line,
    start_col,
    end_line,
    end_col,
    diagnostic.source or 'LSP',
    short_message
  )
end

-- While focusing the input and calling contexts for completion documentation,
-- the input will be the current window. So, find the last used "valid" window.
local function last_used_valid_win()
  local last_used_win = 0
  local latest_lastused = 0

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if is_buf_valid(buf) then
      local last_used = vim.fn.getbufinfo(buf)[1].lastused or 0
      if last_used > latest_lastused then
        latest_lastused = last_used
        last_used_win = win
      end
    end
  end

  return last_used_win
end

---Given a buffer number, returns the file path relative to Neovim's CWD, or nil if not associated with a file.
---Opencode seems to easily ignore directories in the path above its CWD, so it's okay to use paths relative to Neovim's CWD,
---given that we verify the former is inside the latter.
---Unless the user does something weird like set opts.port to an opencode running in an entirely different directory.
---@param buf number
---@return string|nil
local function file_path(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == '' then
    return nil
  end

  return vim.fn.fnamemodify(name, ':.')
end

---Formatted diagnostics for the current buffer.
---@param curr_line_only? boolean Whether to only include diagnostics for the current line.
---@return string|nil
function M.get_coc_diagnostics(curr_line_only)
  local win = last_used_valid_win()
  local buf = vim.api.nvim_win_get_buf(win)

  -- 获取 coc.nvim 的诊断信息
  local diagnostics = get_coc_diagnostics_safely()
  if not diagnostics or #diagnostics == 0 then
    return nil
  end

  local current_line = curr_line_only and vim.api.nvim_win_get_cursor(win)[1] or nil
  local filtered_diagnostics = {}

  -- 过滤当前行的诊断信息（如果需要）
  for _, diagnostic in ipairs(diagnostics) do
    if not current_line or diagnostic.lnum + 1 == current_line then
      table.insert(filtered_diagnostics, diagnostic)
    end
  end

  if #filtered_diagnostics == 0 then
    return nil
  end

  local buf_file_path = file_path(buf)
  local message = #filtered_diagnostics .. ' diagnostics in file `' .. buf_file_path .. '` :\n'

  for _, diagnostic in ipairs(filtered_diagnostics) do
    message = message .. '\n\n' .. format_diagnostic_message(diagnostic, buf_file_path)
  end

  return '\n<Diagnostics>\n' .. message .. '\n</Diagnostics>\n'
end

---Select a diagnostic from coc.nvim and ask opencode to fix it
function M.select_diagnostic_and_fix()
  -- 检查 coc.nvim 是否可用
  if not is_coc_available() then
    vim.notify('coc.nvim is not available', vim.log.levels.WARN)
    return
  end

  -- 获取当前光标位置
  local current_win = vim.api.nvim_get_current_win()
  local current_line = vim.api.nvim_win_get_cursor(current_win)[1]

  -- 获取诊断信息
  local diagnostics = get_coc_diagnostics_safely()
  if not diagnostics or #diagnostics == 0 then
    vim.notify('No diagnostics found', vim.log.levels.INFO)
    return
  end

  -- 过滤包含当前光标行的诊断
  local filtered_diagnostics = {}
  for _, diagnostic in ipairs(diagnostics) do
    local start_line = diagnostic.lnum
    local end_line = diagnostic.endLnum and diagnostic.endLnum or start_line

    -- 检查当前光标行是否在诊断范围内
    if current_line >= start_line and current_line <= end_line then
      table.insert(filtered_diagnostics, diagnostic)
    end
  end

  if #filtered_diagnostics == 0 then
    vim.notify('No diagnostics found at current cursor line', vim.log.levels.INFO)
    return
  end

  -- 格式化诊断信息供选择
  local items = {}
  for i, diagnostic in ipairs(filtered_diagnostics) do
    items[i] = format_diagnostic_message(diagnostic)
  end

  -- 使用 telescope 或 fzf.lua 进行选择
  local function on_select_diagnostic(choice)
    if not choice then
      return
    end

    -- 找到对应的诊断信息
    local index = nil
    for i, item in ipairs(items) do
      if item == choice then
        index = i
        break
      end
    end

    if not index then
      return
    end

    local diagnostic = filtered_diagnostics[index]
    -- 构建诊断范围字符串
    local diagnostic_message = format_diagnostic_message(diagnostic)

    require('opencode').prompt('修复以下问题：\n' .. diagnostic_message)
  end

  -- 检查可用的选择器
  local has_telescope = pcall(require, 'telescope')
  local has_fzf, fzf = pcall(require, 'fzf-lua')

  if has_telescope then
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')

    pickers
        .new({}, {
          prompt_title = 'Select Diagnostic to Fix',
          finder = finders.new_table({ results = items }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              if selection then
                on_select_diagnostic(selection[1])
              end
            end)
            return true
          end,
        })
        :find()
  elseif has_fzf then
    fzf.fzf_exec(items, {
      prompt = 'Select Diagnostic to Fix> ',
      actions = {
        ['default'] = function(selected)
          on_select_diagnostic(selected[1])
        end,
      },
    })
  else
    vim.notify('Neither telescope nor fzf.lua is available', vim.log.levels.ERROR)
  end
end

function M.config()
  vim.g.opencode_opts = {
    provider = {
      enabled = 'snacks',
      snacks = {
        win = {
          enter = true,
        },
      },
    },
    -- contexts = {
    --   ['@diagnostic'] = {
    --     description = 'lsp diagnostics',
    --     value = function()
    --       return M.get_coc_diagnostics(true)
    --     end,
    --   },
    --   ['@diagnostics'] = { description = 'lsp diagnostics', value = M.get_coc_diagnostics },
    -- },
    prompts = {
      fix = {
        description = 'Fix the problem',
        prompt = '修复 @buffer 文件中的以下问题：',
      },
      refactor = {
        description = 'Refactor the file',
        prompt = '/refactor @@buffer',
      },
    },
    events = {
      permissions = {
        enabled = false,
      }
    }
  }
end

-- Set keys after M module is defined to avoid reference issues
M.keys = {
  -- Main opencode commands
  {
    '<leader>ig',
    function()
      require('opencode').toggle()
    end,
    desc = 'Toggle opencode',
  },
  {
    '<leader>iA',
    function()
      require('opencode').ask()
    end,
    desc = 'Ask opencode',
  },
  {
    '<leader>ia',
    function()
      require('opencode').ask('@this: ')
    end,
    desc = 'Ask opencode about this',
  },
  {
    '<leader>in',
    function()
      require('opencode').command('session_new')
    end,
    desc = 'New opencode session',
  },
  {
    '<leader>iy',
    function()
      require('opencode').command('messages_copy')
    end,
    desc = 'Copy last opencode response',
  },
  {
    '<leader>is',
    function()
      require('opencode').select()
    end,
    desc = 'Select opencode prompt',
  },
  {
    '<leader>ie',
    function()
      require('opencode').prompt('Explain @this and its context')
    end,
    desc = 'Explain this code',
  },
  {
    '<leader>id',
    function()
      M.select_diagnostic_and_fix()
    end,
    desc = 'Select diagnostic and fix',
  },
  {
    '<leader>ip',
    function()
      require('opencode').command('session_interrupt')
    end,
    desc = 'Interrupt current session',
  },

  -- Scroll commands
  {
    '<leader>iou',
    function()
      require('opencode').command('messages_half_page_up')
    end,
    desc = 'Messages half page up',
  },
  {
    '<leader>iod',
    function()
      require('opencode').command('messages_half_page_down')
    end,
    desc = 'Messages half page down',
  },
  {
    '<leader>io<space>',
    function()
      require('which-key').show({ keys = '<leader>io', loop = true, delay = 3 })
    end,
    desc = 'Scroll page in hydra mode',
  },

  -- Visual mode commands
  {
    '<leader>ia',
    function()
      require('opencode').ask('@this: ')
    end,
    desc = 'Ask opencode about selection',
    mode = 'v',
  },
  {
    '<leader>is',
    function()
      require('opencode').select()
    end,
    desc = 'Select opencode prompt',
    mode = 'v',
  },
}

return M
