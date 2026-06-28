local M = {}

local group = vim.api.nvim_create_augroup("TerminalConfig", { clear = true })

local function is_terminal(bufnr)
	return bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buftype == "terminal"
end

local function apply_terminal_restore(bufnr)
	if bufnr ~= vim.api.nvim_get_current_buf() or not is_terminal(bufnr) then
		return
	end

	local mode = vim.fn.mode(1)
	local is_terminal_mode = mode == "t"

	if vim.b[bufnr].terminal_restore_insert then
		if not is_terminal_mode then
			vim.cmd("startinsert")
		end
	elseif is_terminal_mode then
		vim.cmd("stopinsert")
	end
end

local function setup_restore_insert()
	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		desc = "Restore terminal mode when entering terminal buffers",
		callback = function(event)
			if is_terminal(event.buf) then
				apply_terminal_restore(event.buf)
			end
		end,
	})

	vim.api.nvim_create_autocmd("ModeChanged", {
		group = group,
		desc = "Remember current terminal mode per buffer",
		callback = function()
			local bufnr = vim.api.nvim_get_current_buf()

			if is_terminal(bufnr) then
				local new_mode = vim.v.event["new_mode"] or vim.fn.mode(1)
				vim.b[bufnr].terminal_restore_insert = new_mode == "t"
			end
		end,
	})
end

function M.setup()
	setup_restore_insert()

	require("terminal.cwd_sync").setup()
	require("terminal.edit").setup()
	require("terminal.pool").setup()
	require("terminal.keymaps").setup()
end

return M
