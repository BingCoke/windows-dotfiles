return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
		---@module 'render-markdown'
		---@type render.md.UserConfig
		opts = {
			render_modes = { "n", "c", "t", "i", "v", "V", "\x16" },
			anti_conceal = {
				enabled = true,
				-- 在 normal 模式(n)下禁用 anti_conceal，只在 insert 和 visual 模式生效
				--disabled_modes = { "n" },
				above = 0,
				below = 0,
				ignore = {
					code_background = true,
					indent = true,
					sign = true,
					virtual_lines = true,
				},
			},
		},
		event = "VeryLazy",
	},
}
