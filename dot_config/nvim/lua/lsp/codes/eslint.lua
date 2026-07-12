local M = {}

local util = require("lspconfig/util")

M.setup = function()
	vim.lsp.enable("eslint", true)
	vim.lsp.config("eslint", {
		root_dir = function(filename)
			if string.find(filename, "node_modules/") then
				return nil
			end
			return util.root_pattern(
				"eslint.config.js",
				"eslint.config.mjs",
				"eslint.config.cjs",
				"eslint.config.ts",
				"eslint.config.mts",
				"eslint.config.cts"
			)()
		end,
	})
end
return M
