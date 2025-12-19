local M = {
  'olimorris/codecompanion.nvim',
  version = '^18.0.0',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {
    interactions = {
      chat = {
        adapter = 'claude_code',
        opts = {
          completion_provider = 'coc',
        },
      },
    },
    display = {
      diff = {
        enabled = true,
        provider = 'split',
      },
    },
    adapters = {
      acp = {
        opts = {
          -- show_presets = false,
        },
        -- ['claude-code'] = function()
        -- return require("codecompanion.adapters").extend("claude_code", {
        --   env = {
        -- -- ANTHROPIC_API_KEY = os.getenv("LITELLM_API_KEY"),
        --   },
        -- })
        -- end,
        opencode = function()
          return require('codecompanion.adapters').extend('opencode', {
            commands = {
              -- The default uses the opencode/config.json value
              default = {
                'opencode',
                'acp',
              },
              kimi_thinking = {
                'opencode',
                'acp',
                '-m',
                'volcengine/kimi-k2-thinking-251104',
              },
              ds_3_2 = {
                'opencode',
                'acp',
                '-m',
                'volcengine/deepseek-v3-2-251201',
              },
            },
          })
        end,
        codex = function()
          return require('codecompanion.adapters').extend('codex', {
            defaults = {
              auth_method = 'codex-api-key', -- "openai-api-key"|"codex-api-key"|"chatgpt"
            },
            env = {
              -- OPENAI_API_KEY = "my-api-key",
            },
          })
        end,
        -- goose = function()
        --   return require("codecompanion.adapters").extend("codex", {
        --     defaults = {

        --     }
        --   })
        -- end,
      },
    },
  },
  keys = {
    {
      '<leader>ic',
      '<cmd>CodeCompanionChat<CR>',
      desc = 'Toggle opencode',
    },
  },
}

return M
