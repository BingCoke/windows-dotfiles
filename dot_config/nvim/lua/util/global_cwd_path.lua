local M = {}

function M.display(path)
	if type(path) ~= "string" or path == "" then
		return ""
	end

	local absolute_path = vim.fs.normalize(path)
	local global_cwd = vim.fs.normalize(vim.fn.getcwd(-1, -1))
	local relative_path = vim.fs.relpath(global_cwd, absolute_path)

	if relative_path and not relative_path:match("^%.%.([/\\]|$)") then
		return relative_path
	end

	return absolute_path
end

return M
