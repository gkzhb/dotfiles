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
        adapter = 'opencode',
      },
    },
    adapters = {
      acp = {
        opts = {
          -- show_presets = false,
        },
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
          return require("codecompanion.adapters").extend("codex", {
            defaults = {
              auth_method = "codex-api-key", -- "openai-api-key"|"codex-api-key"|"chatgpt"
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
}

return M
