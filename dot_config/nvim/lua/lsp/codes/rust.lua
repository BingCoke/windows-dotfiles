local M = {}
local lsp = require("lsp.lsp")
local on_attach = lsp.on_attach
local capabilities = lsp.capabilities

function M.setup()
	vim.lsp.config("rust_analyzer", {
		capabilities = capabilities,
		on_attach = function(cli, buf)
			on_attach(cli, buf)
		end,
		settings = {
			["rust-analyzer"] = {
				cargo = {
					allFeatures = false, -- 少分析一些 features
				},
			},
		},
	})
	vim.lsp.enable("rust_analyzer")
end

return M
