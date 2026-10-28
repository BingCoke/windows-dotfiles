return {
  {
    "zbirenbaum/copilot.lua",
    dependencies = {
      "copilotlsp-nvim/copilot-lsp",
    },
    cmd          = "Copilot",
    event        = "InsertEnter",
    config       = function()
      require("copilot").setup({
        panel = {
          enabled = false,
        },
        suggestion = {
          auto_trigger = true,
          keymap = {
            accept = "<C-f>",
          }
        },
        nes = {
          enabled = false,
        }

      })
    end,
  },
}
