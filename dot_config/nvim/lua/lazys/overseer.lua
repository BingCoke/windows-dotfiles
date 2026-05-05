return {
  {
    "stevearc/overseer.nvim",

    event = "VeryLazy",
    config = function()
      require("overseer").setup({
        task_list = {
          keymaps = {

            ["r"] = { "keymap.run_action", opts = { action = "restart" }, desc = "restart task" },
            ["s"] = { "keymap.run_action", opts = { action = "stop" }, desc = "stop task" }
          },
        }
      })
    end
  }
}
