local function is_terminal(bufnr)
	return vim.bo[bufnr].buftype == "terminal"
end

local function remember_terminal_insert_state(bufnr, was_insert)
	vim.b[bufnr].zellij_nav_restore_insert = was_insert
end

local function restore_terminal_insert_if_needed()
	vim.schedule(function()
		local bufnr = vim.api.nvim_get_current_buf()

		if is_terminal(bufnr) and vim.b[bufnr].zellij_nav_restore_insert then
			vim.cmd("startinsert")
		end
	end)
end

local function nav(short_direction, direction, action)
	if not action then
		action = "move-focus"
	end

	if action ~= "move-focus" and action ~= "move-focus-or-tab" then
		error("invalid action: " .. action)
	end

	local cur_bufnr = vim.api.nvim_get_current_buf()
	local cur_winnr = vim.fn.winnr()

	if is_terminal(cur_bufnr) then
		remember_terminal_insert_state(cur_bufnr, vim.fn.mode(1) == "t")
	end

	vim.api.nvim_command("wincmd " .. short_direction)

	local new_winnr = vim.fn.winnr()
	local at_edge = cur_winnr == new_winnr

	if at_edge then
		vim.fn.jobstart({ "zellij", "action", action, direction }, {
			detach = true,
		})
	end

	restore_terminal_insert_if_needed()
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
