return {

	"swaits/zellij-nav.nvim",
	lazy = true,
	event = "VeryLazy",
	config = function()
		require("zellij-nav").setup()

		local map = vim.keymap.set
		map({ "n" }, "<m-h>", function()
			local start = vim.uv.hrtime()
			require("zellij-nav").left()
			local elapsed_ms = (vim.uv.hrtime() - start) / 1e6
			vim.notify(string.format("[require] %-24s %.3f ms", "left", elapsed_ms), vim.log.levels.INFO)
		end, { desc = "navigate left or tab" })
		map({ "n" }, "<m-j>", "<cmd>ZellijNavigateDown<cr>", { desc = "navigate down" })
		map({ "n" }, "<m-k>", "<cmd>ZellijNavigateUp<cr>", { desc = "navigate up" })
		map({ "n" }, "<M-l>", function()
			local start = vim.uv.hrtime()
			require("zellij-nav").right()
			local elapsed_ms = (vim.uv.hrtime() - start) / 1e6
			vim.notify(string.format("[require] %-24s %.3f ms", "right", elapsed_ms), vim.log.levels.INFO)
		end, { desc = "navigate right or tab" })
	end,
	keys = {},
	opts = {},
}
