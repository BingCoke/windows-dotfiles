if vim.fn.has("win32") == 1 and vim.env.DOTFILES_USE_SHELL == "nu" and vim.fn.executable("nu") == 1 then
	local nu_shell_options = {
		shell = "nu",
		shellcmdflag = "--login --stdin --no-newline -c",
		shellpipe = "| complete | update stderr { ansi strip } | tee { get stderr | save --force --raw %s } | into record",
		shellquote = "",
		shellredir = "out+err> %s",
		shelltemp = false,
		shellxescape = "",
		shellxquote = "",
	}

	for k, v in pairs(nu_shell_options) do
		vim.opt[k] = v
	end
end

-- Terminal setup lives in lua/terminal/init.lua.
