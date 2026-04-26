return {

	"swaits/zellij-nav.nvim",
	lazy = true,
	event = "VeryLazy",
	config = function()
		require("zellij-nav").setup()

		local map = vim.keymap.set
		map({ "n" }, "<m-h>", "<cmd>ZellijNavigateLeft<cr>", { desc = "navigate left or tab" })
		map({ "n" }, "<m-j>", "<cmd>ZellijNavigateDown<cr>", { desc = "navigate down" })
		map({ "n" }, "<m-k>", "<cmd>ZellijNavigateUp<cr>", { desc = "navigate up" })
		map({ "n" }, "<M-l>", "<cmd>ZellijNavigateRight<cr>", { desc = "navigate right or tab" })
	end,
	keys = {},
	opts = {},
}
