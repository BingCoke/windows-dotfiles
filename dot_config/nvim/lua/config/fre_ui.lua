local M = {}

local global_cwd_path = require("util.global_cwd_path")

local function metadata(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	if vim.bo[bufnr].filetype ~= "fre" then
		return nil
	end

	local value = vim.b[bufnr].fre
	if type(value) ~= "table" or type(value.root) ~= "string" then
		return nil
	end

	return value
end

function M.is_buffer(bufnr)
	return metadata(bufnr) ~= nil
end

local function root_label()
	local value = metadata()
	if not value then
		return ""
	end

	local label = global_cwd_path.display(value.root)
	label = label:gsub("%%", "%%%%")

	return label .. (vim.bo.modified and " [+]" or "")
end

function M.tabby_name(bufnr)
	return metadata(bufnr) and "Fre" or nil
end

function M.lualine_component()
	return { root_label, cond = M.is_buffer }
end

return M
