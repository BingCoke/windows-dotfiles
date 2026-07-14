return {
	-- icons
	{
		"nvim-tree/nvim-web-devicons",
	},
	{
		"uga-rosa/ccc.nvim",
		config = function()
			require("ccc").setup({})
		end,
		event = "VeryLazy",
	},
	{
		"axkirillov/hbac.nvim",
		event = "VeryLazy",
		config = function()
			require("hbac").setup({
				autoclose = true,
				threshold = 15,
				close_command = function(bufnr)
					vim.api.nvim_buf_delete(bufnr, {})
				end,
			})
		end,
	},
}
