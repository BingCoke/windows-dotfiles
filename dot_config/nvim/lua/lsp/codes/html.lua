local M = {}


M.setup = function()
	vim.lsp.enable("html")
	vim.lsp.config("html", {
		init_options = {
			provideFormatter = false,
			configurationSection = { "html", "css", "javascript" },
			embeddedLanguages = {
				css = true,
				javascript = true,
			},
		},
	})
end
return M
