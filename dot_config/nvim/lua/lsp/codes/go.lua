local M = {}

M.setup = function()
	vim.lsp.config("gopls", {
		settings = {
			gopls = {},
		},
	})
	vim.lsp.enable("gopls")
end

return M
