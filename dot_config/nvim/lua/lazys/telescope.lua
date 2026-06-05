return {
  {
    'nvim-telescope/telescope-project.nvim',
    dependencies = {
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      local project_actions = require("telescope._extensions.project.actions")
      require('telescope').setup({
        extensions = {
          project = {
            ignore_missing_dirs = true, -- default: false
            hidden_files = true,  -- default: false
            theme = "dropdown",
            order_by = "asc",
            search_by = "title",
            sync_with_nvim_tree = true, -- default false
            -- default for on_project_selected = find project files
            on_project_selected = function(prompt_bufnr)
              local selected_path = project_actions.get_selected_path(prompt_bufnr)
              require("telescope.actions").close(prompt_bufnr)

              local tree_api = require("nvim-tree.api")
              if vim.fn.isdirectory(selected_path) == 1 then
                tree_api.tree.change_root(selected_path)
                tree_api.tree.open({ path = selected_path })
              else
                tree_api.tree.find_file({ buf = selected_path, open = true, update_root = true, focus = true })
              end
            end,
            mappings = {
              n = {
                ['d'] = project_actions.delete_project,
                ['r'] = project_actions.rename_project,
                ['c'] = project_actions.add_project,
                ['C'] = project_actions.add_project_cwd,
                ['f'] = project_actions.find_project_files,
                ['b'] = project_actions.browse_project_files,
                ['s'] = project_actions.search_in_project_files,
                ['R'] = project_actions.recent_project_files,
                ['w'] = project_actions.change_working_directory,
                ['o'] = project_actions.next_cd_scope,
              },
              i = {
                ['<c-d>'] = project_actions.delete_project,
                ['<c-v>'] = project_actions.rename_project,
                ['<c-a>'] = project_actions.add_project,
                ['<c-A>'] = project_actions.add_project_cwd,
                ['<c-f>'] = project_actions.find_project_files,
                ['<c-b>'] = project_actions.browse_project_files,
                ['<c-s>'] = project_actions.search_in_project_files,
                ['<c-r>'] = project_actions.recent_project_files,
                ['<c-l>'] = project_actions.change_working_directory,
                ['<c-o>'] = project_actions.next_cd_scope,
              }
            }
          }
        }
      })
    end
  },
  {
    "stevearc/dressing.nvim",
    lazy = true,
    init = function()
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.select = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.select(...)
      end
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.input = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.input(...)
      end
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "albenisolmos/telescope-oil.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local status, telescope = pcall(require, "telescope")
      if not status then
        vim.notify("没有找到 telescope")
        return
      end

      telescope.setup({
        defaults = {
          -- 打开弹窗后进入的初始模式，默认为 insert，也可以是 normal
          initial_mode = "insert",

          -- 窗口内快捷键
          mappings = {
            i = {
              -- 上下移动
              ["<C-j>"] = "move_selection_next",
              ["<C-k>"] = "move_selection_previous",
              ["<Down>"] = "move_selection_next",
              ["<Up>"] = "move_selection_previous",
              -- 历史记录
              ["<C-n>"] = "cycle_history_next",
              ["<C-p>"] = "cycle_history_prev",
              -- 关闭窗口
              ["<C-c>"] = "close",
              -- 预览窗口上下滚动
              ["<C-u>"] = "preview_scrolling_up",
              ["<C-d>"] = "preview_scrolling_down",
              ["<C-l>"] = "results_scrolling_right",
              ["<C-h>"] = "results_scrolling_left",
              ["<C-v>"] = function(prompt_bufnr)
                -- 触发 Vim 的插入模式 Ctrl+r 然后 + 寄存器
                local keys = vim.api.nvim_replace_termcodes("<C-r>+", true, false, true)
                vim.api.nvim_feedkeys(keys, "t", true)
              end,
              ["<c-s>"] = "file_split",
              ["<c-f>"] = "file_vsplit",
              ["<c-o>"] = "select_tab_drop",
            },
          },
        },
        pickers = {
          -- 内置 pickers 配置
          find_files = {
            file_ignore_patterns = {
              "node_modules",
              "vendor",
              "ios",
              "andriod",
            },
            -- 查找文件换皮肤，支持的参数有： dropdown, cursor, ivy
            -- theme = "dropdown",
            mappings = {
              i = {},
            },
          },
        },

        extensions = {
          ["uo-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
          project = {
            hidden_files = true, -- default: false
            search_by = "title",
          },
          my_file_find = {},
          file_browser = {
            -- disables netrw and use telescope-file-browser in its place
            --hijack_netrw = false,
            mappings = {
              ["i"] = {
                -- your custom insert mode mappings
              },
              ["n"] = {
                -- your custom normal mode mappings
              },
            },
          },
          myprojects = {},
        },
      })

      require("telescope").load_extension("fzf")
      require("telescope").load_extension("oil")
      require("telescope").load_extension("ui-select")
      require 'telescope'.load_extension('project')
      require("telescope").load_extension("ui-select")

      local opt = { noremap = true, silent = true }

      vim.keymap.set("n", "<C-p>", function()
        vim.cmd([[Telescope find_files]])
      end, opt)

      local open_with_oil_or_file = function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        require("telescope.actions").close(prompt_bufnr)
        if not selection then
          return
        end

        local path = selection.path or selection.filename or selection.value
        local stat = vim.loop.fs_stat(path)

        if stat and stat.type == "directory" then
          require("oil").open(path)                    -- 目录 → oil 打开
        else
          vim.cmd("edit " .. vim.fn.fnameescape(path)) -- 文件 → 正常打开
        end
      end

      vim.keymap.set("n", "<leader>pm", function()
        require("telescope.builtin").find_files({
          find_command = { "fd", "--type", "f", "--type", "d", "--hidden", "--strip-cwd-prefix" },
          mappings = {
            i = { ["<CR>"] = open_with_oil_or_file },
            n = { ["<CR>"] = open_with_oil_or_file },
          },
        })
      end)

      -- 全局搜索
      vim.keymap.set("n", "<C-f>", function()
        vim.cmd([[Telescope live_grep]])
      end, opt)
    end,
  },
}
