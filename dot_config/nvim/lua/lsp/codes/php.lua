local M = {}

M.setup = function()
	vim.lsp.enable("intelephense")
	vim.lsp.config("intelephense", {
		init_options = {
			licenceKey = "/Users/bingcoke/.config/intelephense/licence",
		},
		settings = {},
	})
end
return M
