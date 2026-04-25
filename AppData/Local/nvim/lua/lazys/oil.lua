return {
	"stevearc/oil.nvim",
	enabled = true,
	dependencies = { "nvim-tree/nvim-web-devicons" },

	config = function()
		require("oil").setup({
			default_file_explorer = true, -- start up nvim with oil instead of netrw
			columns = {
				"icon",
				-- "permissions",
				-- "size",
				-- "mtime",
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
				["<tab>"] = "actions.preview",

				--["<C-c>"] = { "actions.close", mode = "n" },
				["q"] = { "actions.close", mode = "n" },

				["<C-r>"] = "actions.refresh",

				["_"] = { "actions.open_cwd", mode = "n" },
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

		-- opens parent dir over current active window
		vim.keymap.set("n", "-", function()
			require("oil").toggle_float(vim.fn.getcwd())
		end, { desc = "Open pwd" })

		-- open parent dir in float window
		vim.keymap.set("n", "<M-f>", require("oil").toggle_float)
	end,
}
