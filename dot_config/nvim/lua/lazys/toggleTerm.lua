return {

  {
    "akinsho/toggleterm.nvim",
    version = "*",
    event = "VeryLazy",
    config = function()
      local M = {}

      require("toggleterm").setup({
        shade_terminals = false,
        float_opts = {
          border = "curved",
          title_pos = "center",
        },
      })

      local Terminal = require("toggleterm.terminal").Terminal

      local toggle_origins = {}

      local function terminal_state()
        local bufnr = vim.api.nvim_get_current_buf()

        if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "terminal" then
          return nil
        end

        return {
          bufnr = bufnr,
          mode = vim.fn.mode(1),
          cursor = vim.api.nvim_win_get_cursor(0),
        }
      end

      local function remember_origin(name, term)
        local origin = terminal_state()

        if term:is_open() then
          if origin and vim.api.nvim_get_current_buf() ~= term.bufnr then
            toggle_origins[name] = origin
          end
          return
        end

        toggle_origins[name] = origin
      end

      local function restore_origin(name)
        local origin = toggle_origins[name]
        toggle_origins[name] = nil

        if not origin or origin.mode ~= "t" then
          return
        end

        vim.schedule(function()
          if
            vim.api.nvim_get_current_buf() ~= origin.bufnr
            or not vim.api.nvim_buf_is_valid(origin.bufnr)
            or vim.bo[origin.bufnr].buftype ~= "terminal"
          then
            return
          end

          if origin.cursor then
            pcall(vim.api.nvim_win_set_cursor, 0, origin.cursor)
          end
          vim.b[origin.bufnr].terminal_restore_insert = true
          vim.cmd("startinsert")
        end)
      end

      local function global_cwd()
        return vim.fn.getcwd(-1, -1)
      end

      local map = vim.keymap.set
      -- 复用 opt 参数
      local opt = { noremap = true, silent = true }


      M.term = Terminal:new({
        direction = "float",
        dir = global_cwd(),
        close_on_exit = true,
        display_name = "term",
        on_open = function()
          vim.cmd("startinsert!")
        end,
        on_close = function()
          restore_origin("term")
        end,
      })

      map({ "n", "i", "t" }, "<M-e>", function()
        remember_origin("term", M.term)

        local dir = global_cwd()
        if M.term.job_id and M.term.bufnr and vim.api.nvim_buf_is_valid(M.term.bufnr) then
          M.term:change_dir(dir)
        else
          M.term.dir = dir
        end
        M.term:toggle()
      end, opt)


      M.git = Terminal:new({
        cmd = "lazygit",
        direction = "float",
        dir = global_cwd(),
        close_on_exit = true,
        display_name = "git",
        on_open = function(term)
          vim.cmd("startinsert!")
        end,
        on_close = function()
          restore_origin("git")
        end,
      })

      map({ "n", "i", "t" }, "<M-g>", function()
        remember_origin("git", M.git)

        local dir = global_cwd()
        if M.git.dir ~= dir and M.git.bufnr and vim.api.nvim_buf_is_valid(M.git.bufnr) then
          M.git:shutdown()
        end
        M.git.dir = dir
        M.git:toggle()
      end, opt)

      function _G.set_terminal_keymaps()
        local opts = { buffer = 0 }
        vim.api.nvim_buf_set_keymap(0, "t", "<Esc>", "<Esc>", { noremap = true, silent = true })

        -- 使用 <C-\><C-n> 退出终端模式
        vim.api.nvim_buf_set_keymap(0, "t", "<C-\\><C-n>", "<C-\\><C-n>", { noremap = true, silent = true })
        -- vim.api.nvim_buf_set_keymap(0, "t", "<leader><Esc>", "<C-\\><C-n>", { noremap = true, silent = true })
      end

      -- if you only want these mappings for toggle term use term://*toggleterm#* instead
      vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")

      return M
    end,
  },
}
