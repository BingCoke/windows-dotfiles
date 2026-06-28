local M = {}

local state = {
  bufnr = nil,
  job_id = nil,
}

local function is_valid_buffer(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr)
end

local function focus_existing_window(bufnr)
  local wins = vim.fn.win_findbuf(bufnr)
  if #wins == 0 then
    return false
  end

  vim.api.nvim_set_current_win(wins[1])
  vim.cmd("startinsert")
  return true
end

local function start_terminal(bufnr)
  local cwd = vim.fn.getcwd(-1, -1)
  local env = require("terminal.edit").env()

  vim.b[bufnr].global_cwd_terminal = true
  vim.b[bufnr].osc7_dir = cwd
  vim.bo[bufnr].bufhidden = "hide"

  state.job_id = vim.fn.termopen(vim.o.shell, {
    cwd = cwd,
    env = env,
    on_exit = function()
      vim.schedule(function()
        if state.bufnr == bufnr then
          state.job_id = nil
          state.bufnr = nil
        end
      end)
    end,
  })

end

function M.open()
  if is_valid_buffer(state.bufnr) then
    if focus_existing_window(state.bufnr) then
      return
    end

    vim.api.nvim_win_set_buf(0, state.bufnr)
    vim.cmd("startinsert")
    return
  end

  local bufnr = vim.api.nvim_create_buf(false, false)
  state.bufnr = bufnr
  vim.api.nvim_win_set_buf(0, bufnr)
  start_terminal(bufnr)
  vim.cmd("startinsert")
end

return M
