local lsp = require("lsp.lsp")
local on_attach = lsp.on_attach
local capabilities = lsp.capabilities

local simple_lsp_by_filetype = {
	sh = { "bashls" },
	bash = { "bashls" },
	zsh = { "bashls" },
	xml = { "lemminx" },
	xsd = { "lemminx" },
	xsl = { "lemminx" },
	ps1 = { "powershell_es" },
	powershell = { "powershell_es" },
	arduino = { "arduino_language_server" },
	css = { "css_variables", "cssls" },
	scss = { "css_variables", "cssls" },
	less = { "css_variables", "cssls" },
	tsp = { "tsp_server" },
	proto = { "buf_ls" },
	yaml = { "yamlls" },
	yml = { "yamlls" },
	toml = { "taplo" },
}

local lsp_by_filetype = {
	lua = { "lua" },
	typescript = { "ts", "eslint", "tailwind" },
	javascript = { "ts", "eslint", "tailwind" },
	typescriptreact = { "ts", "eslint", "tailwind" },
	javascriptreact = { "ts", "eslint", "tailwind" },
	vue = { "ts", "eslint", "tailwind" },
	python = { "python" },
	go = { "go" },
	html = { "html", "tailwind" },
	css = { "tailwind" },
	scss = { "tailwind" },
	rust = { "rust" },
	php = { "php" },
	json = { "json" },
	jsonc = { "json" },
	markdown = { "markdown" },
}

local loaded_code_lsps = {}
local loaded_simple_lsps = {}

local function setup_code_lsp(name)
	if loaded_code_lsps[name] then
		return
	end
	--local start = vim.uv.hrtime()

	local states, mod = pcall(require, "lsp.codes." .. name)
	if not states then
		print("No LSP support for " .. name)
		return
	end

	mod.setup()
	loaded_code_lsps[name] = true
	--local elapsed_ms = (vim.uv.hrtime() - start) / 1e6
	--vim.notify(string.format("[require] %-24s %.3f ms", name, elapsed_ms), vim.log.levels.INFO)
end

local function setup_simple_lsp(name)
	if loaded_simple_lsps[name] then
		return
	end
	--local start = vim.uv.hrtime()

	vim.lsp.config(name, {
		capabilities = capabilities,
		on_attach = on_attach,
	})
	vim.lsp.enable(name)
	loaded_simple_lsps[name] = true

	--local elapsed_ms = (vim.uv.hrtime() - start) / 1e6
	--vim.notify(string.format("[require] %-24s %.3f ms", name, elapsed_ms), vim.log.levels.INFO)
end

local function setup_filetype_lsp(filetype)
	local code_lsps = lsp_by_filetype[filetype]
	if code_lsps then
		for _, name in ipairs(code_lsps) do
			setup_code_lsp(name)
		end
		return
	end

	local simple_lsps = simple_lsp_by_filetype[filetype]
	if simple_lsps then
		for _, name in ipairs(simple_lsps) do
			setup_simple_lsp(name)
		end
	end
end

vim.api.nvim_create_autocmd("FileType", {
	callback = function(args)
		setup_filetype_lsp(args.match)
	end,
})

