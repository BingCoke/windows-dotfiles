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
            reveal_cwd  = '',
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

      local function global_cwd()
        return vim.fn.getcwd(-1, -1)
      end

      local function full_path(path)
        return (vim.fn.fnamemodify(path, ":p"):gsub("/+", "/"):gsub("(.)/$", "%1"))
      end

      local function parent_path(path)
        path = full_path(path)
        if path == "/" then
          return nil
        end
        return (path:match("^.*/"):gsub("/+", "/"):gsub("(.)/$", "%1"))
      end

      local function reveal_global_cwd()
        local state = MiniFiles.get_explorer_state()
        if state == nil then
          return
        end

        local branch = state.branch
        local depth_focus = state.depth_focus
        local cwd = full_path(global_cwd())
        local pattern = string.format("^%s%s.", vim.pesc(cwd), cwd == "/" and "" or "/")
        while branch[1]:find(pattern) ~= nil do
          local parent = parent_path(branch[1])
          if parent == nil then
            break
          end
          table.insert(branch, 1, parent)
          depth_focus = depth_focus + 1
        end

        MiniFiles.set_branch(branch, { depth_focus = depth_focus })
      end

      local function open_file(command)
        return function()
          local entry = MiniFiles.get_fs_entry()
          if entry == nil or entry.fs_type ~= "file" then
            return
          end

          local target = MiniFiles.get_explorer_state().target_window
          if not MiniFiles.close() then
            return
          end

          vim.api.nvim_set_current_win(target)
          vim.cmd(command .. " " .. vim.fn.fnameescape(entry.path))
        end
      end

      local function reveal_target()
        local buf = vim.api.nvim_get_current_buf()
        if vim.bo[buf].filetype == "minifiles" then
          local state = MiniFiles.get_explorer_state()
          local win = state and state.target_window
          if win and vim.api.nvim_win_is_valid(win) then
            buf = vim.api.nvim_win_get_buf(win)
          end
        end

        if vim.bo[buf].filetype == "oil" then
          local oil = require("oil")
          local dir = oil.get_current_dir(buf)
          if not dir then
            return nil
          end

          local win = vim.fn.bufwinid(buf)
          if win ~= -1 then
            local entry = oil.get_entry_on_line(buf, vim.api.nvim_win_get_cursor(win)[1])
            if entry and entry.name ~= "." and entry.name ~= ".." then
              return vim.fs.joinpath(dir, entry.name)
            end
          end
          return dir
        end

        if vim.bo[buf].buftype ~= "" then
          return nil
        end
        local name = vim.api.nvim_buf_get_name(buf)
        if name == "" then
          return nil
        end
        return name
      end

      local function branch_from_root(path)
        local root = full_path(global_cwd())
        local target = full_path(path)
        if target == root then
          return root, { root }
        end

        local pattern = string.format("^%s%s.", vim.pesc(root), root == "/" and "" or "/")
        if target:find(pattern) == nil then
          return nil, nil
        end

        local branch = { target }
        local cursor = parent_path(target)
        while cursor and cursor ~= root do
          table.insert(branch, 1, cursor)
          cursor = parent_path(cursor)
        end
        table.insert(branch, 1, root)
        return root, branch
      end

      local function reveal_current()
        local path = reveal_target()
        if path == nil or (vim.fn.filereadable(path) == 0 and vim.fn.isdirectory(path) == 0) then
          vim.notify("No file or oil location to reveal", vim.log.levels.WARN)
          return
        end

        local files = require("mini.files")
        local root, branch = branch_from_root(path)
        if branch == nil then
          files.open(path, false)
          return
        end

        local state = MiniFiles.get_explorer_state()
        if state == nil or full_path(state.anchor) ~= root then
          files.open(root, true)
          state = MiniFiles.get_explorer_state()
          if state == nil or full_path(state.anchor) ~= root then
            return
          end
        end

        MiniFiles.set_branch(branch)
      end

      vim.keymap.set("n", "<M-b>", function()
        local files = require("mini.files")
        if files.close() == nil then
          files.open(global_cwd())
        end
      end, { desc = "Toggle mini.files at global root" })

      vim.keymap.set("n", "<M-B>", reveal_current, { desc = "Reveal current file or oil entry" })

      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesBufferCreate",
        callback = function(args)
          local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = args.data.buf_id, desc = desc, nowait = true })
          end

          map("<CR>", function()
            local entry = MiniFiles.get_fs_entry()
            if entry == nil then return end

            if MiniFiles.close() then
              vim.cmd("edit " .. vim.fn.fnameescape(entry.path))
            end
          end, "Edit entry")
          map("s", open_file("belowright vsplit"), "Open in vertical split")
          map("S", open_file("belowright split"), "Open in horizontal split")
          map("t", open_file("tabedit"), "Open in new tab")
          map("@", reveal_global_cwd, "Reveal global cwd")
          map("<leader>w", MiniFiles.synchronize, "Synchronize")
          map("Y", function()
            local entry = MiniFiles.get_fs_entry()
            if entry == nil then return end
            require("util.copy_relative_path")(entry.path)
          end, "Copy path")
          map("<M-v>", function()
            local state = MiniFiles.get_explorer_state()
            if state == nil then return end

            local dir = state.branch[state.depth_focus]
            local target = state.target_window
            if dir == nil or vim.fn.isdirectory(dir) == 0 then
              vim.notify("No mini.files directory to open in oil", vim.log.levels.WARN)
              return
            end

            if not MiniFiles.close() then return end
            if target and vim.api.nvim_win_is_valid(target) then
              vim.api.nvim_set_current_win(target)
            end
            require("oil").open(dir)
          end, "Open oil at mini.files directory")
        end,
      })
    end

  },

}
