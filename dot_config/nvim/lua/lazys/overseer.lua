return {
  {
    "stevearc/overseer.nvim",

    event = "VeryLazy",
    config = function()
      local last_compile_cmd = nil

      vim.api.nvim_create_user_command("Compile", function(opts)
        local cmd = opts.args

        if cmd == "" then
          cmd = last_compile_cmd
        else
          last_compile_cmd = cmd
        end

        if not cmd or cmd == "" then
          vim.notify("No previous compile command", vim.log.levels.WARN)
          return
        end

        local task = require("overseer").new_task({
          cmd = cmd,
          components = {
            -- 不用 dock，避免 task list
            { "open_output",         direction = "horizontal", on_start = "always", focus = true },

            "on_exit_set_status",
            "on_complete_notify",
            { "on_complete_dispose", timeout = 300 },
          },
        })

        task:start()
      end, {
        nargs = "*",
        complete = "shellcmd",
      })

      vim.keymap.set("n", "!", ":Compile ", { desc = "Compile command" })
      vim.keymap.set("n", "<leader>!", "<cmd>Compile<CR>", { desc = "Repeat compile command" })

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
