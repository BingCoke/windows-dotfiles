return {
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		event = "VeryLazy",
		config = function()
			-- ========================================
			-- 基础配置
			-- ========================================
			require("toggleterm").setup({
				shade_terminals = false,
				size = function(term)
					if term.direction == "horizontal" then
						return 15
					elseif term.direction == "vertical" then
						return vim.o.columns * 0.4
					end
				end,
				float_opts = {
					border = "curved",
					title_pos = "center",
				},
			})

			local Terminal = require("toggleterm.terminal").Terminal

			-- ========================================
			-- 工具函数
			-- ========================================
			local function global_cwd()
				return vim.fn.getcwd(-1, -1)
			end

			-- ========================================
			-- 终端实例配置
			-- ========================================
			_G.terms = {
				-- 1. 主终端 - 日常命令
				main = Terminal:new({
					cmd = "bash",
					display_name = "Main",
					direction = "float",
					dir = global_cwd(),
					float_opts = {
						border = "curved",
					},
					on_open = function(term)
						vim.cmd("startinsert!")
					end,
				}),

				-- 2. Git 终端
				git = Terminal:new({
					cmd = "lazygit",
					display_name = "Git",
					direction = "float",
					dir = global_cwd(),
					float_opts = {
						border = "curved",
					},
					on_open = function(term)
						vim.cmd("startinsert!")
					end,
					on_close = function(term)
						-- Git 关闭时重新加载目录以刷新状态
						vim.cmd("checktime")
					end,
				}),

				-- 3. 编译终端 - 长时间运行
				build = Terminal:new({
					cmd = "bash",
					display_name = "Build",
					direction = "horizontal",
					size = 15,
					dir = global_cwd(),
					on_open = function(term)
						vim.cmd("startinsert!")
					end,
				}),

				-- 4. 开发服务器终端
				dev = Terminal:new({
					cmd = "bash",
					display_name = "Dev",
					direction = "horizontal",
					size = 15,
					dir = global_cwd(),
					on_open = function(term)
						vim.cmd("startinsert!")
					end,
				}),
			}

			-- ========================================
			-- 快捷键配置
			-- ========================================
			local map = vim.keymap.set
			local opt = { noremap = true, silent = true }

			-- 终端管理快捷键（使用 leader+e 前缀，e = execute/terminal）
			map("n", "<leader>ee", "<Cmd>TermSelect<CR>", { desc = "Select Terminal" })

			map({ "n", "i", "t" }, "<M-e>", function()
				_G.terms.main:toggle()
			end, vim.tbl_extend("force", opt, { desc = "Toggle Main Terminal" }))

			-- 快速访问各个终端（使用 leader+e 前缀）
			map({ "n", "i", "t" }, "<leader>em", function()
				_G.terms.main:toggle()
			end, vim.tbl_extend("force", opt, { desc = "Toggle Main Terminal" }))

			map({ "n", "i", "t" }, "<leader>eg", function()
				-- 每次打开 git 时更新工作目录
				local dir = global_cwd()
				if _G.terms.git.dir ~= dir and _G.terms.git.bufnr and vim.api.nvim_buf_is_valid(_G.terms.git.bufnr) then
					_G.terms.git:shutdown()
				end
				_G.terms.git.dir = dir
				_G.terms.git:toggle()
			end, vim.tbl_extend("force", opt, { desc = "Toggle Git Terminal" }))

			map({ "n", "i", "t" }, "<leader>eb", function()
				_G.terms.build:toggle()
			end, vim.tbl_extend("force", opt, { desc = "Toggle Build Terminal" }))

			map({ "n", "i", "t" }, "<leader>ed", function()
				_G.terms.dev:toggle()
			end, vim.tbl_extend("force", opt, { desc = "Toggle Dev Terminal" }))

			-- ========================================
			-- 终端模式按键映射
			-- ========================================
			function _G.set_terminal_keymaps()
				local opts = { buffer = 0 }
				-- Ctrl+hjkl 在窗口间导航
				vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
				vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
				vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
				vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
			end

			vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
		end,
	},
}
