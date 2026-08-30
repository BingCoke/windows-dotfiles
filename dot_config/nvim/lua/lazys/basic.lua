return {
  -- icons
  {
    "nvim-tree/nvim-web-devicons",
  },
  {
    "uga-rosa/ccc.nvim",
    config = function()
      require("ccc").setup({})
    end,
    event = "VeryLazy",
  },

  {
    "m00qek/baleia.nvim",
    config = function()
      vim.g.baleia = require("baleia").setup({})

      -- 所有的 dump 文件 不能配置任何 column
      vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = "*.dump",
        callback = function(args)
          vim.g.baleia.once(args.buf)
          vim.api.nvim_set_option_value("modified", false, {
            buf = args.buf,
          })
          vim.wo.number = false
          vim.wo.relativenumber = false
          vim.wo.signcolumn = "no"
          vim.wo.foldcolumn = "0"
          vim.wo.statuscolumn = ""
        end,
      })

      -- Command to colorize the current buffer
      vim.api.nvim_create_user_command("BaleiaColorize", function(args)
        vim.g.baleia.once(vim.api.nvim_get_current_buf())
        vim.api.nvim_set_option_value("modified", false, {
          buf = args.buf,
        })
      end, { bang = true })

      -- Command to show logs
      vim.api.nvim_create_user_command("BaleiaLogs", vim.cmd.messages, { bang = true })
    end
  },
  {
    "axkirillov/hbac.nvim",
    event = "VeryLazy",
    config = function()
      require("hbac").setup({
        autoclose = true,
        threshold = 15,
        close_command = function(bufnr)
          vim.api.nvim_buf_delete(bufnr, {})
        end,
      })
    end,
  },
}
