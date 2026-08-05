local global_cwd_path = require("util.global_cwd_path")

return function(path)
	local display_path = global_cwd_path.display(path)
	if display_path == "" then
		return
	end

	vim.fn.setreg("+", display_path)
	vim.notify("Copied: " .. display_path)
end
