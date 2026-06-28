local M = {}

local MAX_TERMINALS = 10
local terminals = {}
local sequence = 0

local function resolve_cwd(scope)
  if scope == "local" then
    return vim.fn.getcwd(0)
  end

  if scope == "global" then
    return vim.fn.getcwd(-1, -1)
  end
end

local function next_sequence()
  sequence = sequence + 1
  return sequence
end

local function index_of(bufnr)
  for index, terminal in ipairs(terminals) do
    if terminal.bufnr == bufnr then
      return index
    end
  end
end

local function mark_used(bufnr)
  local index = index_of(bufnr)
  if index then
    terminals[index].last_used = next_sequence()
  end
end

local function remove_from_pool(bufnr)
  local index = index_of(bufnr)
  if index then
    table.remove(terminals, index)
  end
end

local function delete_terminal(terminal)
  if terminal.job_id and terminal.job_id > 0 then
    pcall(vim.fn.jobstop, terminal.job_id)
  end

  if terminal.bufnr and vim.api.nvim_buf_is_valid(terminal.bufnr) then
    pcall(vim.api.nvim_buf_delete, terminal.bufnr, { force = true })
  end
end

local function prune_invalid_terminals()
  for index = #terminals, 1, -1 do
    local terminal = terminals[index]
    if not terminal.bufnr or not vim.api.nvim_buf_is_valid(terminal.bufnr) then
      table.remove(terminals, index)
    end
  end
end

local function evict_if_full()
  prune_invalid_terminals()

  if #terminals < MAX_TERMINALS then
    return
  end

  local evict_index = 1
  for index, terminal in ipairs(terminals) do
    if terminal.last_used < terminals[evict_index].last_used then
      evict_index = index
    end
  end

  local evicted = table.remove(terminals, evict_index)
  delete_terminal(evicted)
end

local function open_window(direction)
  if direction == "horizontal" then
    vim.cmd("botright split")
  elseif direction == "vertical" then
    vim.cmd("botright vsplit")
  elseif direction == "tab" then
    vim.cmd("tabnew")
  elseif direction ~= "current" then
    vim.notify("Unknown terminal direction: " .. tostring(direction), vim.log.levels.ERROR)
    return false
  end

  return true
end

local function create_terminal(direction, cwd_scope)
  local pwd = resolve_cwd(cwd_scope)
  local env = require("terminal.edit").env()

  if not open_window(direction) then
    return
  end

  local bufnr = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_win_set_buf(0, bufnr)
  vim.bo[bufnr].bufhidden = "hide"

  local job_id = vim.fn.termopen(vim.o.shell, {
    cwd = pwd,
    env = env,
    on_exit = function()
      vim.schedule(function()
        remove_from_pool(bufnr)
      end)
    end,
  })

  local terminal = {
    bufnr = bufnr,
    job_id = job_id,
    cwd = pwd,
    last_used = next_sequence(),
  }

  table.insert(terminals, terminal)
  vim.cmd("startinsert")
end

function M.open(direction, cwd_scope)
  evict_if_full()
  create_terminal(direction, cwd_scope)
end

function M.count()
  prune_invalid_terminals()
  return #terminals
end

function M.setup()
  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("ManagedTerminalPool", { clear = true }),
    callback = function(event)
      mark_used(event.buf)
    end,
  })
end

return M
