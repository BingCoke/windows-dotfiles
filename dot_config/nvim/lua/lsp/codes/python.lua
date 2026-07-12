local M = {}

M.setup = function()
	vim.lsp.config("basedpyright", {
		settings = {
			basedpyright = {
				analysis = {
					typeCheckingMode = "basic",
					diagnosticSeverityOverrides = {
						reportUnusedImport = false,
					},
				},
				--ignore = { "*" },
			},
		},
	})

	vim.lsp.enable("basedpyright", true)
end
return M
