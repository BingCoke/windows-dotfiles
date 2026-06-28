return {
	"stevearc/oil.nvim",
	enabled = true,
	dependencies = { "nvim-tree/nvim-web-devicons" },

	config = function()
		require("oil").setup({
			default_file_explorer = true, -- start up nvim with oil instead of netrw
			cleanup_delay_ms = 60000,
			columns = {
				"icon",
			},
			use_default_keymaps = false,
			keymaps = {
				["g?"] = { "actions.show_help", mode = "n" },
				["<CR>"] = "actions.select",
				["gd"] = "actions.select",
				["gp"] = { "actions.parent", mode = "n" },

				["s"] = { "actions.select", opts = { vertical = true } },
				["S"] = { "actions.select", opts = { horizontal = true } },

				["t"] = { "actions.select", opts = { tab = true } },

				["q"] = { "actions.close", mode = "n" },
				["K"] = { "actions.preview", mode = "n" },

				["<C-r>"] = "actions.refresh",

				["_"] = { "actions.open_cwd", mode = "n" },
				["`"] = { "actions.cd", mode = "n" },
				["gl"] = { "actions.cd", opts = { scope = "win" }, mode = "n" },
				["gs"] = { "actions.change_sort", mode = "n" },
				["gx"] = "actions.open_external",
				["g."] = { "actions.toggle_hidden", mode = "n" },
				["g\\"] = { "actions.toggle_trash", mode = "n" },
			},
			delete_to_trash = true,
			float = {
				border = "rounded", -- 将边框样式设置为 "rounded"
			},
			view_options = {
				show_hidden = true,
			},
			skip_confirm_for_simple_edits = true,
		})

		vim.api.nvim_create_autocmd({ "User", "BufEnter", "WinEnter" }, {
			pattern = { "OilEnter", "*" },
			group = vim.api.nvim_create_augroup("OilAutoLcd", { clear = true }),
			callback = function(args)
				local bufnr = args.data and args.data.buf or args.buf or vim.api.nvim_get_current_buf()

				if vim.bo[bufnr].filetype ~= "oil" then
					return
				end

				local dir = require("oil").get_current_dir(bufnr)

				if not dir then
					return
				end

				vim.cmd.lcd(vim.fn.fnameescape(dir))
			end,
		})

		-- opens parent dir over current active window
		vim.keymap.set({ "n" }, "-", function()
			require("oil").toggle_float(vim.fn.getcwd(-1, -1))
		end, { desc = "Open global cwd" })

		vim.keymap.set({ "n", "i", "t" }, "<M-v>", function()
			local dir = nil

			if vim.bo.buftype == "terminal" then
				dir = vim.fn.getcwd(0, 0)
			end

			require("oil").open(dir)
		end, { desc = "Oil: toggle buffer" })

		vim.keymap.set({ "n", "i", "t" }, "<M-f>", function()
			local dir = nil

			if vim.bo.buftype == "terminal" then
				dir = vim.fn.getcwd(0, 0)
			end

			require("oil").toggle_float(dir)
		end, { desc = "Oil: toggle float" })
	end,
}
