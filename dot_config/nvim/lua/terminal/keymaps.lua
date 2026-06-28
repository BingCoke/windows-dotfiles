local M = {}

function M.setup()
  local map = vim.keymap.set
  local opt = { noremap = true, silent = true }
  local terminal_pool = require("terminal.pool")
  local cwd_terminal = require("terminal.cwd")

  local function terminal_map(lhs, direction, cwd_scope, desc)
    map("n", lhs, function()
      terminal_pool.open(direction, cwd_scope)
    end, vim.tbl_extend("force", opt, { desc = desc }))
  end

  terminal_map("<leader>lh", "horizontal", "local", "Open local cwd horizontal terminal")
  terminal_map("<leader>lv", "vertical", "local", "Open local cwd vertical terminal")
  terminal_map("<leader>lc", "current", "local", "Open local cwd terminal in current window")
  terminal_map("<leader>lt", "tab", "local", "Open local cwd tab terminal")

  terminal_map("<leader>gh", "horizontal", "global", "Open global pwd horizontal terminal")
  terminal_map("<leader>gv", "vertical", "global", "Open global pwd vertical terminal")
  terminal_map("<leader>gc", "current", "global", "Open global pwd terminal in current window")
  terminal_map("<leader>gt", "tab", "global", "Open global pwd tab terminal")

  map("n", "<leader>cd", function()
    cwd_terminal.open()
  end, vim.tbl_extend("force", opt, { desc = "Open global cwd controller terminal" }))
end

return M
