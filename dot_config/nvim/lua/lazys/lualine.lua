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
						{
							"filename",
							file_status = true, -- displays file status (readonly status, modified status)
							path = 1, -- 0 = just filename, 1 = relative path, 2 = absolute path
						},
					},
					lualine_x = {
						"rest",
						{
							"diagnostics",
							sources = { "nvim_diagnostic" },
							symbols = { error = " ", warn = " ", info = " ", hint = " " },
						},
						{ "filetype", color = { bg = "" } },
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
						{
							"filename",
							file_status = true, -- displays file status (readonly status, modified status)
							path = 1, -- 0 = just filename, 1 = relative path, 2 = absolute path
						},
					},
					lualine_x = {
						"rest",
						{
							"diagnostics",
							sources = { "nvim_diagnostic" },
							symbols = { error = " ", warn = " ", info = " ", hint = " " },
						},
						--"encoding",
						{ "filetype", color = { bg = "" } },
					},
					lualine_z = {
						{
							"location",
							color = { fg = "grey" },
						},
					},
				},
				tabline = {},
				extensions = { "fugitive", "neo-tree", "nvim-dap-ui", "mason", "lazy", "man" },
			})

			local ok, t = pcall(require, "transparent")

			if ok then
				t.clear_prefix("lualine")
			end
		end,
		-- enabled = false
	},
}
