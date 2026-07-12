return {
	{
		"nvim-lualine/lualine.nvim",
		enabled = true,
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			local status, lualine = pcall(require, "lualine")
			if not status then
				return
			end

			local transparent_theme = {
				normal  = { a = { bg = nil }, b = { bg = nil }, c = { bg = nil }, x = { bg = nil }, y = { bg = nil }, z = { bg = nil } },
				insert  = { a = { bg = nil }, b = { bg = nil }, c = { bg = nil }, x = { bg = nil }, y = { bg = nil }, z = { bg = nil } },
				visual  = { a = { bg = nil }, b = { bg = nil }, c = { bg = nil }, x = { bg = nil }, y = { bg = nil }, z = { bg = nil } },
				replace = { a = { bg = nil }, b = { bg = nil }, c = { bg = nil }, x = { bg = nil }, y = { bg = nil }, z = { bg = nil } },
				command = { a = { bg = nil }, b = { bg = nil }, c = { bg = nil }, x = { bg = nil }, y = { bg = nil }, z = { bg = nil } },
				inactive = { a = { bg = nil }, b = { bg = nil }, c = { bg = nil }, x = { bg = nil }, y = { bg = nil }, z = { bg = nil } },
			}

			lualine.setup({
				options = {
					icons_enabled = true,
					theme = transparent_theme,
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
						--{
						--	"filename",
						--	file_status = true, -- displays file status (readonly status, modified status)
						--	path = 1, -- 0 = just filename, 1 = relative path, 2 = absolute path
						--},
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
				inactive_sections = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = {
						{
							"filename",
							file_status = true, -- displays file status (readonly status, modified status)
							path = 1, -- 0 = just filename, 1 = relative path, 2 = absolute path
						},
					},
					lualine_x = { { "location", color = { fg = "grey" } } },
					lualine_y = {},
					lualine_z = {},
				},
				tabline = {},
				extensions = { "fugitive", "neo-tree", "nvim-dap-ui", "mason", "lazy", "man" },
			})
      
			require("transparent").clear_prefix("lualine")
		end,
		event = "VeryLazy",
		-- enabled = false
	},
}
