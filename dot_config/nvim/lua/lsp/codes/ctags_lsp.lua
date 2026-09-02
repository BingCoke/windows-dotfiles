local M = {}

local util = require("lspconfig/util")

M.setup = function()
  vim.lsp.config("ctags_lsp", {
    cmd = { "ctags-lsp" },
    filetypes = { "bash", "nu", "fish" }, -- Change this to the language(s) nvim should attach the LSP to
  })
  vim.lsp.enable("ctags_lsp", true)
end
return M
