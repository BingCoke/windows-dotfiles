return {
  {
    'nvim-telescope/telescope-project.nvim',
    dependencies = {
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      local project_actions = require("telescope._extensions.project.actions")
      local project_utils = require("telescope._extensions.project.utils")
      local project_finders = require("telescope._extensions.project.finders")
      local telescope_actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")
      local builtin = require("telescope.builtin")
      local project_order_by = "asc"
      local project_hidden_files = true
      local project_sync_with_nvim_tree = true

      local function refresh_project_picker(prompt_bufnr)
        local ok, picker = pcall(action_state.get_current_picker, prompt_bufnr)
        if not ok or not picker then
          return
        end

        picker:refresh(project_finders.project_finder({}, project_utils.get_projects(project_order_by)), { reset_prompt = true })
      end

      local function safe_git_root()
        local cwd = vim.loop.cwd()
        local out = vim.fn.systemlist({ "git", "-C", cwd, "rev-parse", "--show-toplevel" })
        if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
          return cwd
        end

        return tostring(out[1]):gsub("\027.*\007", "")
      end

      local function safe_add_project(prompt_bufnr)
        project_actions.add_project_path(safe_git_root())
        refresh_project_picker(prompt_bufnr)
      end

      local function current_cd_command()
        local scope = project_actions.get_cd_scope()
        return ({ tab = "tcd", window = "lcd", global = "cd" })[scope] or "tcd"
      end

      local function safe_change_project_dir(project_path, cd_cmd)
        if not project_path or vim.fn.isdirectory(project_path) ~= 1 then
          print("The path '" .. tostring(project_path) .. "' does not exist")
          return false
        end

        project_utils.update_last_accessed_project_time(project_path)
        vim.cmd(cd_cmd .. " " .. vim.fn.fnameescape(project_path))

        if project_sync_with_nvim_tree then
          project_utils.open_in_nvim_tree(project_path)
        end

        return true
      end

      local function safe_find_project_files(prompt_bufnr)
        local project_path = project_actions.get_selected_path(prompt_bufnr)
        telescope_actions.close(prompt_bufnr)
        if safe_change_project_dir(project_path, current_cd_command()) then
          vim.schedule(function()
            builtin.find_files({ cwd = project_path, hidden = project_hidden_files })
          end)
        end
      end

      local function safe_browse_project_files(prompt_bufnr)
        local ok, file_browser = pcall(require, "telescope._extensions.file_browser")
        if not ok then
          vim.notify("telescope-file-browser.nvim is required to use this action!", vim.log.levels.ERROR, { title = "telescope-project.nvim" })
          return
        end

        local project_path = project_actions.get_selected_path(prompt_bufnr)
        telescope_actions.close(prompt_bufnr)
        if safe_change_project_dir(project_path, current_cd_command()) then
          vim.schedule(function()
            file_browser.exports.file_browser({ cwd = project_path })
          end)
        end
      end

      local function safe_search_in_project_files(prompt_bufnr)
        local project_path = project_actions.get_selected_path(prompt_bufnr)
        telescope_actions.close(prompt_bufnr)
        if safe_change_project_dir(project_path, "lcd") then
          vim.schedule(function()
            builtin.live_grep({ cwd = project_path })
          end)
        end
      end

      local function safe_recent_project_files(prompt_bufnr)
        local project_path = project_actions.get_selected_path(prompt_bufnr)
        telescope_actions.close(prompt_bufnr)
        if safe_change_project_dir(project_path, "lcd") then
          vim.schedule(function()
            builtin.oldfiles({ cwd_only = true })
          end)
        end
      end

      local function safe_change_working_directory(prompt_bufnr)
        local project_path = project_actions.get_selected_path(prompt_bufnr)
        telescope_actions.close(prompt_bufnr)
        safe_change_project_dir(project_path, "tcd")
      end
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
                ['c'] = safe_add_project,
                ['C'] = project_actions.add_project_cwd,
                ['f'] = safe_find_project_files,
                ['b'] = safe_browse_project_files,
                ['s'] = safe_search_in_project_files,
                ['R'] = safe_recent_project_files,
                ['w'] = safe_change_working_directory,
                ['o'] = project_actions.next_cd_scope,
              },
              i = {
                ['<c-d>'] = project_actions.delete_project,
                ['<c-v>'] = project_actions.rename_project,
                ['<c-a>'] = safe_add_project,
                ['<c-A>'] = project_actions.add_project_cwd,
                ['<c-f>'] = safe_find_project_files,
                ['<c-b>'] = safe_browse_project_files,
                ['<c-s>'] = safe_search_in_project_files,
                ['<c-r>'] = safe_recent_project_files,
                ['<c-l>'] = safe_change_working_directory,
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
