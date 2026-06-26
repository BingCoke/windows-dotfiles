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

local function osc7_to_dir(sequence)
	if type(sequence) == "table" then
		sequence = sequence.sequence or ""
	end

	if sequence == "" or not sequence:match("^\027%]7;") then
		return nil
	end

	local uri = sequence:match("^\027%]7;(.*)$")
	if not uri then
		return nil
	end

	local dir = uri:gsub("^file://[^/]*", "")
	dir = vim.uri_decode(dir)

	if vim.fn.has("win32") == 1 then
		dir = dir:gsub("^/([A-Za-z]:)", "%1")
		dir = dir:gsub("/", "\\")
	end

	if dir == "" then
		return nil
	end

	return dir
end

local terminal_cwd_group = vim.api.nvim_create_augroup("TerminalOSC7", { clear = true })

local function apply_terminal_cwd(bufnr)
	local dir = vim.b[bufnr].osc7_dir
	if not dir or vim.fn.isdirectory(dir) == 0 then
		return
	end

	if vim.fn.getcwd() == dir then
		return
	end

	vim.cmd("lcd " .. vim.fn.fnameescape(dir))
end

vim.api.nvim_create_autocmd("TermRequest", {
	group = terminal_cwd_group,
	desc = "Sync terminal cwd from OSC 7",
	callback = function(ev)
		local dir = osc7_to_dir(ev.data)
		if not dir or vim.fn.isdirectory(dir) == 0 then
			return
		end

		vim.b[ev.buf].osc7_dir = dir
		if vim.api.nvim_get_current_buf() == ev.buf then
			apply_terminal_cwd(ev.buf)
		end
	end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "DirChanged" }, {
	group = terminal_cwd_group,
	callback = function()
		apply_terminal_cwd(vim.api.nvim_get_current_buf())
	end,
})
