return {
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		--lazy = false,
		--priority = 1000,
		event = "VeryLazy",
		config = function()
			local status, lualine = pcall(require, "lualine")
			if not status then
				return
			end

			local fre_ui = require("config.fre_ui")
			local global_cwd_path = require("util.global_cwd_path")


			local function global_filename_component()
				return {
					"filename",
					file_status = false,
					path = 2,
					shorting_target = 0,
					cond = function()
						return not fre_ui.is_buffer()
					end,
					fmt = function(default_name)
						local path = vim.api.nvim_buf_get_name(0)
						local name = path == "" and default_name or global_cwd_path.display(path)
						local symbols = {}

						if vim.bo.modified then
							table.insert(symbols, "[+]")
						end
						if not vim.bo.modifiable or vim.bo.readonly then
							table.insert(symbols, "[-]")
						end

						return name .. (#symbols > 0 and " " .. table.concat(symbols) or "")
					end,
				}
			end


			lualine.setup({
				options = {
					icons_enabled = true,
					theme = "auto",
					section_separators = { left = "", right = "" },
					component_separators = { left = "", right = "" },
					disabled_filetypes = { "Outline" },
				},
				sections = {
					lualine_a = {
						{
							"mode",
							icons_enabled = false,
							color = { fg = "grey" },
						},
					},
					lualine_b = {
						"branch",
					},
					lualine_c = {
						global_filename_component(),
						fre_ui.lualine_component(),
					},
					lualine_x = {
						{
							"diagnostics",
							sources = { "nvim_diagnostic" },
							symbols = { error = " ", warn = " ", info = " ", hint = " " },
						},
					},
					lualine_z = {
						{
							"location",
							color = { fg = "grey" },
						},
					},
				},
				inactive_sections = {
					lualine_a = {
						{
							"mode",
							icons_enabled = false,
							draw_empty = true,
							color = { fg = "grey" },
						},
					},
					lualine_b = {
						"branch",
					},
					lualine_c = {
						global_filename_component(),
						fre_ui.lualine_component(),
					},
					lualine_x = {
						{
							"diagnostics",
							sources = { "nvim_diagnostic" },
							symbols = { error = " ", warn = " ", info = " ", hint = " " },
						},
					},
					lualine_z = {
						{
							"location",
							color = { fg = "grey" },
						},
					},
				},
				tabline = {},
				extensions = {
					"fugitive",
					"neo-tree",
					"nvim-dap-ui",
					"mason",
					"lazy",
					"man",
					"toggleterm",
					"trouble",
				},
			})

			local ok, t = pcall(require, "transparent")

			if ok then
				t.clear_prefix("lualine")
			end
		end,
		-- enabled = false
	},
}
