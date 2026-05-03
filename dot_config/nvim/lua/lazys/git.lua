local language = require("language").language
local ts = require("language").ts

return {
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
  },
  {
    "NeogitOrg/neogit",
    lazy = true,
    dependencies = {
      "esmuellert/codediff.nvim", -- optional
      "nvim-telescope/telescope.nvim", -- optional
    },
    cmd = "Neogit",
    keys = {
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Show Neogit UI" }
    }
  },

  {
    "lewis6991/gitsigns.nvim",
    opts = {},
    config = function()
      require("gitsigns").setup({
        -- 查看git编辑情况
        current_line_blame = true,
        --numhl = true, -- Toggle with `:Gitsigns toggle_numhl`
        --linehl = true, -- Toggle with `:Gitsigns toggle_linehl`
      })
    end,
    ft = language,
  },
}
