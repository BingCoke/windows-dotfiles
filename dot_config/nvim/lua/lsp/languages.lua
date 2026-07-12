
-- Simple LSP servers (using vim.lsp.enable)
local simple_lsps = {
	"qmlls",
	"neocmake",
	"bashls",
	"lemminx",
	"powershell_es",
	"arduino_language_server",
	"css_variables",
	"cssls",
	"tsp_server",
	"buf_ls",
	"yamlls",
	"taplo",
	"clangd",
  "lua_ls"
}

-- Complex LSP servers (using lsp.codes.<name>.setup())
local code_lsps = {
	"flutter",
	"ts",
	"eslint",
	"tailwind",
	"python",
	"go",
	"html",
	"rust",
	"php",
	"json",
	"markdown_oxide",
}

local loaded_code_lsps = {}
local loaded_simple_lsps = {}

local function setup_code_lsp(name)
	if loaded_code_lsps[name] then
		return
	end

	local success, mod = pcall(require, "lsp.codes." .. name)
	if not success then
		print("No LSP support for " .. name)
		return
	end

	mod.setup()
	loaded_code_lsps[name] = true
end

local function setup_simple_lsp(name)
	if loaded_simple_lsps[name] then
		return
	end

	vim.lsp.enable(name)
	loaded_simple_lsps[name] = true
end

-- Setup all simple LSP servers
for _, name in ipairs(simple_lsps) do
	setup_simple_lsp(name)
end

-- Setup all code LSP servers
for _, name in ipairs(code_lsps) do
	setup_code_lsp(name)
end
