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

			local function relative_to_global_cwd(path)
				if not path or path == "" then
					return ""
				end

				local absolute_path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
				local relative_path = vim.fs.relpath(vim.fn.getcwd(-1, -1), absolute_path)

				return relative_path or vim.fn.fnamemodify(absolute_path, ":~")
			end

			local function global_filename_component()
				return {
					"filename",
					file_status = false,
					path = 2,
					shorting_target = 0,
					fmt = function(default_name)
						local path = vim.api.nvim_buf_get_name(0)
						local name = path == "" and default_name or relative_to_global_cwd(path)
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

			local oil_extension = vim.deepcopy(require("lualine.extensions.oil"))
			oil_extension.sections.lualine_a[1] = {
				oil_extension.sections.lualine_a[1],
				fmt = relative_to_global_cwd,
				color = "Normal",
			}

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
					oil_extension,
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
