return {
  {
    "freeo/md-table.nvim",
    cmd = "MdTable",
    keys = { { "<leader>mt", "<cmd>MdTable<cr>", desc = "Read table" } }
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    lazy = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      -- 表格保持源码，交给 vim-table-mode 对齐
      pipe_table = { enabled = false },
    },
    keys = {
      { "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle Markdown rendering" },
    },
  },
  {
    "dhruvasagar/vim-table-mode",
    ft = "markdown",
    init = function()
      vim.g.table_mode_map_prefix = "<leader>mt"
      vim.g.table_mode_corner = "|"
      -- <leader>mtr 自己管，auto 关掉也保留
      vim.g.table_mode_realign_map = ""
      -- 不覆盖 basic.lua 的 updatetime = 100
      vim.g.table_mode_update_time = 100
    end,
    config = function()
      local function setup(buf)
        --  vim.cmd("TableModeEnable")
        -- 手动格式化：auto 关掉时也要能用
        vim.keymap.set("n", "<leader>mtr", "<cmd>TableModeRealign<cr>", {
          buffer = buf,
          desc = "Format current table",
        })
      end

      setup(0)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(args)
          setup(args.buf)
        end,
      })
    end,
  },
}
