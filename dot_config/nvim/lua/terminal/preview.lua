local M = {}

-- Parse file location from a line of text
-- Supports formats: file:line:col and file:line
-- Returns { file = string, lnum = number, col = number } or nil
function M.parse_file_location(line)
  if not line or line == "" then
    return nil
  end

  -- Try file:line:col:content format first (ripgrep --vimgrep)
  -- Extract only file:line:col part before any content
  local file, lnum, col = line:match("^([^:]+):(%d+):(%d+):")
  if file and lnum then
    return {
      file = file,
      lnum = tonumber(lnum),
      col = tonumber(col) or 1,
    }
  end

  -- Try file:line:col without trailing colon
  file, lnum, col = line:match("^([^:]+):(%d+):(%d+)$")
  if file and lnum then
    return {
      file = file,
      lnum = tonumber(lnum),
      col = tonumber(col) or 1,
    }
  end

  -- Try file:line format (grep -n)
  file, lnum = line:match("^([^:]+):(%d+):")
  if not file then
    file, lnum = line:match("^([^:]+):(%d+)$")
  end
  
  if file and lnum then
    return {
      file = file,
      lnum = tonumber(lnum),
      col = 1,
    }
  end

  return nil
end

-- Find existing preview window in current tab
-- Returns window ID or nil
local function find_preview_window()
  local tabpage = vim.api.nvim_get_current_tabpage()
  local windows = vim.api.nvim_tabpage_list_wins(tabpage)
  
  for _, win in ipairs(windows) do
    if vim.api.nvim_win_is_valid(win) then
      local ok, is_preview = pcall(vim.api.nvim_win_get_var, win, "is_terminal_preview")
      if ok and is_preview then
        return win
      end
    end
  end
  
  return nil
end

-- Create a new preview window above current window
-- Returns window ID
local function create_preview_window()
  -- Save current window
  local current_win = vim.api.nvim_get_current_win()
  
  -- Create horizontal split above
  vim.cmd("aboveleft split")
  
  local preview_win = vim.api.nvim_get_current_win()
  
  -- Mark this as preview window
  vim.api.nvim_win_set_var(preview_win, "is_terminal_preview", true)
  
  -- Return to original window
  vim.api.nvim_set_current_win(current_win)
  
  return preview_win
end

-- Get existing preview window or create new one
-- Returns window ID
function M.get_or_create_preview_window()
  local preview_win = find_preview_window()
  
  -- Validate window is still valid
  if preview_win and vim.api.nvim_win_is_valid(preview_win) then
    return preview_win
  end
  
  return create_preview_window()
end

-- Check if file exists and is readable
-- Handles relative paths based on terminal cwd
local function resolve_and_validate_file(file)
  -- Try absolute path first
  if vim.fn.filereadable(file) == 1 then
    return file
  end
  
  -- Try relative to terminal's cwd
  local cwd = vim.fn.getcwd()
  local full_path = vim.fn.fnamemodify(cwd .. '/' .. file, ':p')
  
  if vim.fn.filereadable(full_path) == 1 then
    return full_path
  end
  
  return nil
end

-- Preview file at location parsed from current line
function M.preview_current_line()
  local line = vim.api.nvim_get_current_line()
  local location = M.parse_file_location(line)
  
  if not location then
    vim.notify("No file location found on current line", vim.log.levels.WARN)
    return
  end
  
  local resolved_file = resolve_and_validate_file(location.file)
  if not resolved_file then
    vim.notify("File not found: " .. location.file, vim.log.levels.ERROR)
    return
  end
  
  -- Save current window
  local terminal_win = vim.api.nvim_get_current_win()
  
  -- Get or create preview window
  local preview_win = M.get_or_create_preview_window()
  
  -- Open file in preview window
  vim.api.nvim_win_call(preview_win, function()
    -- Check if current buffer in preview window already has this file
    local current_buf = vim.api.nvim_win_get_buf(preview_win)
    local current_file = vim.api.nvim_buf_get_name(current_buf)
    
    -- Only edit if it's a different file
    if current_file ~= resolved_file then
      vim.cmd("edit " .. vim.fn.fnameescape(resolved_file))
    end
    
    -- Jump to line and column
    vim.api.nvim_win_set_cursor(preview_win, {location.lnum, location.col - 1})
    -- Center the line
    vim.cmd("normal! zz")
  end)
  
  -- Return focus to terminal
  vim.api.nvim_set_current_win(terminal_win)
end

-- Setup preview functionality
-- Registers autocmd to set Tab keymap in terminal buffers
function M.setup()
  local group = vim.api.nvim_create_augroup("TerminalPreview", { clear = true })
  
  vim.api.nvim_create_autocmd("TermOpen", {
    group = group,
    desc = "Setup preview keymap for terminal buffers",
    callback = function(event)
      vim.keymap.set("n", "<Tab>", function()
        M.preview_current_line()
      end, {
        buffer = event.buf,
        noremap = true,
        silent = true,
        desc = "Preview file at cursor",
      })
    end,
  })
end

return M

