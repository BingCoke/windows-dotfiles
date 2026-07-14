return function(path)
	local relative_path = vim.fs.relpath(vim.fn.getcwd(-1, -1), vim.fs.normalize(path))
	if not relative_path then
		vim.notify("Unable to make path relative to global cwd", vim.log.levels.WARN)
		return
	end

	vim.fn.setreg("+", relative_path)
	vim.notify("Copied: " .. relative_path)
end
