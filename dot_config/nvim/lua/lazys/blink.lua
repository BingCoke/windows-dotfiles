local use_blink = require("config.completion").use_blink

return {
	"saghen/blink.cmp",
	enabled = use_blink,
	dependencies = {
		"saghen/blink.lib",
		"rafamadriz/friendly-snippets",
		"L3MON4D3/LuaSnip",
	},
  commit = "cfe100ccac24b0a622d7b9f04aa8c9f3e7624a16",
	build = function()
		require("blink.cmp").build():pwait()
	end,
	event = { "InsertEnter", "CmdlineEnter" },
	config = function()
		require("config.blink")
	end,
}
