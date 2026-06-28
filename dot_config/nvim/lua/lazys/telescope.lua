return {
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
			"nvim-telescope/telescope-file-browser.nvim",
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
							["<C-v>"] = function()
								-- 触发 Vim 的插入模式 Ctrl+r 然后 + 寄存器
								local keys = vim.api.nvim_replace_termcodes("<C-r>+", true, false, true)
								vim.api.nvim_feedkeys(keys, "t", true)
							end,
							["<c-s>"] = "file_split",
							["<c-f>"] = "file_vsplit",
							["<c-o>"] = "select_tab",
						},
						n = {},
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
			require("telescope").load_extension("ui-select")

			local opt = { noremap = true, silent = true }

			local builtin = require("telescope.builtin")

			local function global_cwd()
				return vim.fn.getcwd(-1, -1)
			end

			vim.keymap.set("n", "<C-p>", function()
				builtin.find_files({ cwd = global_cwd() })
			end, opt)

			-- 全局搜索
			vim.keymap.set("n", "<C-f>", function()
				builtin.live_grep({ cwd = global_cwd() })
			end, opt)

		end,
	},
}
