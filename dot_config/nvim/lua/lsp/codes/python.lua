local M = {}
local lsp = require("lsp.lsp")
local on_attach = lsp.on_attach
local capabilities = lsp.capabilities

M.setup = function()
  vim.lsp.config("basedpyright", {
    on_attach = function(cli, buf)
      on_attach(cli, buf)
    end,
    capabilities = capabilities,
    --root_dir = util.root_pattern(unpack(root_files)),
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
