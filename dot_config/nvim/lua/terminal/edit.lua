local M = {}

local state = {
  script_dir = nil,
}

local function path_separator()
  return vim.fn.has("win32") == 1 and ";" or ":"
end

local function config_script_dir()
  return vim.fs.normalize(vim.fn.stdpath("config") .. "/script")
end

local function path_contains(dir, path)
  path = path or vim.env.PATH or ""
  local sep = path_separator()
  for entry in string.gmatch(path, "([^" .. vim.pesc(sep) .. "]+)") do
    if vim.fs.normalize(entry) == dir then
      return true
    end
  end
  return false
end

local function prepend_to_path(path, dir)
  path = path or ""
  if path_contains(dir, path) then
    return path
  end

  local sep = path_separator()
  if path == "" then
    return dir
  end

  return dir .. sep .. path
end

local function ensure_server()
  if vim.v.servername ~= "" then
    return
  end

  pcall(vim.fn.serverstart)
end

local function ensure_posix_script_executable(script_dir)
  if vim.fn.has("win32") == 1 then
    return
  end

  local script = script_dir .. "/nvim"
  if vim.fn.filereadable(script) == 1 then
    pcall(vim.fn.system, { "chmod", "+x", script })
  end
end

local function edit_file(path)
  if not path or path == "" then
    vim.notify("Usage: nvim <file>", vim.log.levels.WARN)
    return
  end

  vim.cmd.edit(vim.fn.fnameescape(path))
end

local function sequence_from_event(data)
  if type(data) == "table" then
    return data.sequence or ""
  end

  return data or ""
end

local function focus_terminal_window(bufnr)
  if vim.api.nvim_get_current_buf() == bufnr then
    return true
  end

  local wins = vim.fn.win_findbuf(bufnr)
  if #wins == 0 then
    return false
  end

  vim.api.nvim_set_current_win(wins[1])
  return true
end

local function setup_osc_listener()
  vim.api.nvim_create_autocmd("TermRequest", {
    group = vim.api.nvim_create_augroup("TerminalEditOSC", { clear = true }),
    desc = "Open files requested by terminal editor shims",
    callback = function(event)
      local sequence = sequence_from_event(event.data)
      state.last_termrequest = sequence
      local path = sequence:match("^\027%]777;pi%-nvim;(.-)\027\\$")
        or sequence:match("^\027%]777;pi%-nvim;(.-)\007$")
        or sequence:match("^\027%]777;pi%-nvim;(.+)$")

      if sequence:match("^\027%]777;pi%-nvim%-debug") then
        M.debug()
        return
      end

      if not path or path == "" then
        return
      end

      vim.schedule(function()
        if focus_terminal_window(event.buf) then
          edit_file(path)
        end
      end)
    end,
  })
end

local function debug_lines()
  local script_dir = state.script_dir or config_script_dir()
  local posix_script = script_dir .. "/nvim"
  local windows_script = script_dir .. "/nvim.cmd"
  local bufnr = vim.api.nvim_get_current_buf()

  return {
    "terminal-edit debug",
    "os: " .. jit.os,
    "vim.v.servername: " .. tostring(vim.v.servername),
    "vim.env.NVIM: " .. tostring(vim.env.NVIM),
    "vim.v.progpath: " .. tostring(vim.v.progpath),
    "script_dir: " .. script_dir,
    "script/nvim readable: " .. tostring(vim.fn.filereadable(posix_script) == 1),
    "script/nvim.cmd readable: " .. tostring(vim.fn.filereadable(windows_script) == 1),
    "PATH contains script_dir: " .. tostring(path_contains(script_dir)),
    "executable('nvim'): " .. tostring(vim.fn.executable("nvim")),
    "current bufnr: " .. tostring(bufnr),
    "current buftype: " .. tostring(vim.bo[bufnr].buftype),
    "current terminal_restore_insert: " .. tostring(vim.b[bufnr].terminal_restore_insert),
    "current osc7_dir: " .. tostring(vim.b[bufnr].osc7_dir),
    "cwd: " .. vim.fn.getcwd(),
    "last TermRequest: " .. tostring(state.last_termrequest),
  }
end

function M.debug()
  local lines = debug_lines()
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  return ""
end

function M.open_from_remote(path)
  vim.schedule(function()
    edit_file(path)
  end)
  return ""
end

function M.env(extra)
  local script_dir = state.script_dir or config_script_dir()
  local env = {
    PATH = prepend_to_path(vim.env.PATH, script_dir),
    EDITOR = "nvim",
    VISUAL = "nvim",
    GIT_EDITOR = "nvim",
  }

  if extra then
    env = vim.tbl_extend("force", env, extra)
  end

  return env
end

function M.setup()
  local script_dir = config_script_dir()
  state.script_dir = script_dir

  ensure_server()
  ensure_posix_script_executable(script_dir)
  -- Do not mutate Neovim's global PATH. Only terminals opened through our
  -- terminal module get PATH/EDITOR injection via M.env().
  setup_osc_listener()

  vim.api.nvim_create_user_command("TerminalEditDebug", function()
    M.debug()
  end, {
    force = true,
    desc = "Show terminal editor shim diagnostics",
  })
end

return M
