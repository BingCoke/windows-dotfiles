local M = {}

function M.setup(target_line, target_column)
  target_line = tonumber(target_line)
  target_column = tonumber(target_column)

  if not target_line or not target_column or target_line < 1 or target_column < 1 then
    return
  end

  local pending = false
  local group = vim.api.nvim_create_augroup("KittyScrollbackCursor", { clear = true })

  local function place_cursor()
    pending = false

    local line_count = vim.api.nvim_buf_line_count(0)
    local line = math.min(target_line, line_count)
    local byte_column = vim.fn.virtcol2col(0, line, target_column)

    vim.api.nvim_win_set_cursor(0, { line, math.max(byte_column - 1, 0) })
  end

  vim.api.nvim_create_autocmd("TextChanged", {
    group = group,
    callback = function()
      if not pending then
        pending = true
        vim.defer_fn(place_cursor, 0)
      end
    end,
  })
end

return M
