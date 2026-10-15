return {
  {
    'nvim-mini/mini.files',
    version = false,
    config = function()
      require("mini.files").setup(
        {
          -- Customization of shown content
          content = {
            -- Predicate for which file system entries to show
            filter = nil,
            -- Highlight group to use for a file system entry
            highlight = nil,
            -- Prefix text and highlight to show to the left of file system entry
            prefix = nil,
            -- Order in which to show file system entries
            sort = nil,
          },

          -- Module mappings created only inside explorer.
          -- Use `''` (empty string) to not create one.
          mappings = {
            close       = 'q',
            go_out      = '',
            go_in       = 'L',
            go_in_plus  = '',
            go_out_plus = 'H',
            mark_goto   = "'",
            mark_set    = 'm',
            reset       = '<BS>',
            reveal_cwd  = '@',
            show_help   = 'g?',
            synchronize = '=',
            trim_left   = '<',
            trim_right  = '>',
          },

          -- General options
          options = {
            -- Whether to delete permanently or move into module-specific trash
            permanent_delete = false,
            -- Whether to use for editing directories
            use_as_default_explorer = false,
            -- Timeout for synchronous LSP integration requests
            lsp_timeout = 1000,
          },

          -- Customization of explorer windows
          windows = {
            -- Maximum number of windows to show side by side
            max_number = math.huge,
            -- Whether to show preview of file/directory under cursor
            preview = true,
            -- Width of focused window
            width_focus = 50,
            -- Width of non-focused window
            width_nofocus = 15,
            -- Width of preview window
            width_preview = 60,
          },
        }
      )

      vim.keymap.set("n", "<M-b>", function()
        local files = require("mini.files")
        if files.close() == nil then
          files.open()
        end
      end, { desc = "Toggle mini.files" })

      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesBufferCreate",
        callback = function(args)
          vim.keymap.set("n", "<CR>", function()
            local entry = MiniFiles.get_fs_entry()
            if entry == nil then return end

            if MiniFiles.close() then
              vim.cmd("edit " .. vim.fn.fnameescape(entry.path))
            end
          end, {
            buffer = args.data.buf_id,
            desc = "Edit entry",
          })
        end,
      })
    end

  },

}
