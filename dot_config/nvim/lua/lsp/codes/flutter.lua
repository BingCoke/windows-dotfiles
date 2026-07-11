local M = {}

local lsp = require("lsp.lsp")
local on_attach = lsp.on_attach
local capabilities = lsp.capabilities

M.setup = function()
	-- alternatively you can override the default configs
	require("flutter-tools").setup({
		lsp = {
			on_attach = on_attach,
			capabilities = capabilities, -- e.g. lsp_status capabilities
		},
	})

end
return M
