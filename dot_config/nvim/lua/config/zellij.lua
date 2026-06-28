local function nav(short_direction, direction, action)
  if not action then
    action = "move-focus"
  end

  if action ~= "move-focus" and action ~= "move-focus-or-tab" then
    error("invalid action: " .. action)
  end

  local cur_winnr = vim.fn.winnr()

  vim.api.nvim_command("wincmd " .. short_direction)

  local new_winnr = vim.fn.winnr()
  local at_edge = cur_winnr == new_winnr

  if at_edge then
    vim.fn.jobstart({ "zellij", "action", action, direction }, {
      detach = true,
    })
  end

end

local M = {}

function M.up()
  nav("k", "up", nil)
end

function M.down()
  nav("j", "down", nil)
end

function M.right()
  nav("l", "right", nil)
end

function M.left()
  nav("h", "left", nil)
end

function M.up_tab()
  nav("k", "up", "move-focus-or-tab")
end

function M.down_tab()
  nav("j", "down", "move-focus-or-tab")
end

function M.right_tab()
  nav("l", "right", "move-focus-or-tab")
end

function M.left_tab()
  nav("h", "left", "move-focus-or-tab")
end

local map = vim.keymap.set

map({ "n", "t", "i" }, "<m-h>", function()
  M.left()
end, { desc = "navigate left or tab" })

map({ "n", "t", "i" }, "<m-j>", function()
  M.down()
end, { desc = "navigate down" })

map({ "n", "t", "i" }, "<m-k>", function()
  M.up()
end, { desc = "navigate up" })

map({ "n", "t", "i" }, "<M-l>", function()
  M.right()
end, { desc = "navigate right or tab" })

return M
