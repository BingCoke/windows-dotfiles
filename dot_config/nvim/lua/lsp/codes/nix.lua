local M = {}


M.setup = function()
  vim.lsp.config("nil", {
    cmd = { "nil" },
    filetypes = { "nix" },
    root_markers = { "flake.nix", ".git" },
  })
  vim.lsp.enable("nil")
end
return M
