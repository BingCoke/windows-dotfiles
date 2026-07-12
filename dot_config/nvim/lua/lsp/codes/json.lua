local M = {}

M.setup = function()
	vim.lsp.enable("jsonls")
	vim.lsp.config("jsonls", {
		settings = {
			json = {
				schemas = {
					{
						fileMatch = { "package.json" },
						url = "https://json.schemastore.org/package.json",
					},
					{
						fileMatch = { "tsconfig.json", "tsconfig.*.json" },
						url = "http://json.schemastore.org/tsconfig",
					},
					{
						fileMatch = { "biome.json" },
						url = "https://biomejs.dev/schemas/1.4.1/schema.json",
					},
				},
			},
		},
	})
end
return M
