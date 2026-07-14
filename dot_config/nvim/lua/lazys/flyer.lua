return {
	{
		"A7Lavinraj/fyler.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		event = "VeryLazy",
		config = function()
			local fyler = require("fyler")

			fyler.setup({
				follow_current_file = false,
				extensions = {
					git = { enabled = true, inline = true },
					watcher = { enabled = true },
				},
				integrations = {
					icon = "nvim_web_devicons",
				},
				mappings = {
					n = {
						["<M-v>"] = {
							action = "visit",
							args = { parent = true },
						},
						["."] = {
							action = "visit",
							args = { cursor = true },
						},
						["<BS>"] = {
							action = "shrink",
							args = { parent = true },
						},
						["<C-R>"] = {
							action = "refresh",
							args = { recursive = true, force = true },
						},
						["s"] = {
							action = "select",
							args = { split = true },
						},
						["S"] = {
							action = "select",
							args = { vsplit = true },
						},
						["t"] = {
							action = "select",
							args = { tabedit = true },
						},
						["<CR>"] = {
							action = "select",
							args = { pick = true },
						},
						["<2-LeftMouse>"] = {
							action = "select",
							args = { pick = true },
						},
						["="] = {
							action = "visit",
						},
						["g."] = {
							action = "toggle_ui",
							args = { "hidden_items" },
						},
						["H"] = {
							action = "toggle_ui",
							args = { "hidden_items" },
						},
						["gi"] = {
							action = "toggle_ui",
							args = { "indent_guides" },
						},
						["q"] = {
							action = "close",
						},
					},
				},
				kind_presets = {
					floating = {
						border = "rounded",
						height = "80%",
						width = "60%",
						col = "center",
						row = "center",
						mappings = {
							n = {
								["t"] = {
									action = "select",
									args = { tabedit = true, close = true },
								},
							},
						},
					},
					split_left = {
						width = "25%",
					},
				},
				ui = {
					hidden_items = {
						switches = { "dotfiles" },
					},
					indent_guides = true,
				},
			})

			local opt = { noremap = true, silent = true }

			local function toggle_floating(opts)
				if fyler.getcwd() ~= nil then
					fyler.close()
					return
				end

				fyler.open(opts)
			end

			-- Left split toggle
			vim.keymap.set("n", "<M-m>", function()
				fyler.toggle({
					kind = "split_left",
					path = vim.fn.getcwd(),
				})
			end, opt)

			vim.keymap.set("n", "<M-M>", function()
				fyler.toggle({
					kind = "split_left",
					path = vim.fn.getcwd(),
					follow_current_file = true,
				})
			end, opt)

			-- Floating window toggle
			vim.keymap.set("n", "\\", function()
				toggle_floating({
					kind = "floating",
					path = vim.fn.getcwd(),
				})
			end, opt)

			-- Floating window toggle with follow current file
			vim.keymap.set("n", "|", function()
				toggle_floating({
					kind = "floating",
					path = vim.fn.getcwd(),
					follow_current_file = true,
				})
			end, opt)
		end,
	},
}
