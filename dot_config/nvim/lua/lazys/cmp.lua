local use_blink = require("config.completion").use_blink

return {
	{
		"L3MON4D3/LuaSnip",
		version = "2.*",
		build = "make install_jsregexp",
		event = "BufReadPre",
		config = function()
			require("luasnip").config.setup({
				history = true,
			})
		end,
	},
	-- cmp
	{
		"hrsh7th/nvim-cmp",
		enabled = not use_blink,
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lua",
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
		},
		config = function()
			require("cmp.cmp")
		end,
	},
	{
		"saecki/crates.nvim",
		enabled = not use_blink,
		tag = "v0.3.0",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local cmp = require("cmp")
			cmp.setup.buffer({ sources = { { name = "crates" } } })
		end,
		ft = { "toml" },
	},
	{
		"not-manu/filemention.nvim",
		enabled = not use_blink,
		event = "InsertEnter",
		opts = {},
	},
}
