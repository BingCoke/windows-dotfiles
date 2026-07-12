local M = {}

M.setup = function()
	-- alternatively you can override the default configs
	require("flutter-tools").setup({
		lsp = {},
	})
end
return M
