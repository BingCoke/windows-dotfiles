return {
	{
		"ahmedkhalf/project.nvim",
		event = "VeryLazy",
		config = function()
			local status, project = pcall(require, "project_nvim")
			if not status then
				vim.notify("没有找到 project_nvim")
				return
			end

			-- nvim-tree 支持
			project.setup({
				--manual_mode = false,
				detection_methods = { "lsp", "pattern" },
				patterns = {
					".git",
					".svn",
					".idea",
				},
				show_hidden = true,
				exclude_dirs = { "~/.cargo/*" },
			})

			local telescope = require("telescope")
			pcall(telescope.load_extension, "projects")
		end,
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
			require("telescope").load_extension("myprojects")
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
					require("oil").open(path) -- 目录 → oil 打开
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
