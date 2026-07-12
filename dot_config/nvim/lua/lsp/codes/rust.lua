local M = {}

function M.setup()
	vim.lsp.config("rust_analyzer", {
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
