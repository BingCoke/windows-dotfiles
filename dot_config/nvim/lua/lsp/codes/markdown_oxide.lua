local lsp = require("lsp.lsp")

local M = {}

-- Todo 切换函数（从 markdown.lua 迁移）
local function markdown_todo()
	local line = vim.api.nvim_get_current_line()
	local prefix = string.sub(line, 1, 5)

	if prefix == "- [x]" or prefix == "- [ ]" then
		local new = ""
		if prefix == "- [ ]" then
			new = "- [x]"
		elseif prefix == "- [x]" then
			new = "- [ ]"
		end
		vim.api.nvim_set_current_line(new .. string.sub(line, 6))
	else
		vim.api.nvim_set_current_line("- [ ] " .. line)
		local currentPos = vim.api.nvim_win_get_cursor(0)
		local newPos = { currentPos[1], currentPos[2] + 6 }
		vim.api.nvim_win_set_cursor(0, newPos)
	end
end

-- 标题添加函数（从 markdown.lua 迁移）
local function markdown_head()
	local line = vim.api.nvim_get_current_line()
	local prefix = string.sub(line, 1, 1)
	local new = ""
	if prefix == "#" then
		new = "#"
	else
		new = "# "
	end
	vim.api.nvim_set_current_line(new .. line)
	local currentPos = vim.api.nvim_win_get_cursor(0)
	local newPos = { currentPos[1], currentPos[2] + 1 }
	vim.api.nvim_win_set_cursor(0, newPos)
end

function M.setup()
	vim.api.nvim_create_autocmd("LspAttach", {
		callback = function(ev)
			local client = vim.lsp.get_client_by_id(ev.data.client_id)

			if not client then
				return
			end

			if client.name == "markdown_oxide" then
				local bufnr = ev.buf

				-- Markdown 快捷键（从 markdown.lua 迁移）
				local opts = { silent = true, buffer = bufnr, noremap = true }
				vim.keymap.set("i", "<c-l>", markdown_todo, opts)
				vim.keymap.set("i", "<c-h>", markdown_head, opts)
				vim.keymap.set("n", "<leader>m", ":MarkdownPreview<CR>", opts)

				-- 注册 Daily Notes 命令
				if client.server_capabilities.executeCommandProvider then
					-- :Daily <relative_date>
					vim.api.nvim_buf_create_user_command(bufnr, "Daily", function(args)
						local params = {
							command = "jump",
							arguments = { args.args },
						}
						client.request("workspace/executeCommand", params, function(err, result)
							if err then
								vim.notify("Daily command failed: " .. vim.inspect(err), vim.log.levels.ERROR)
							end
						end, bufnr)
					end, { nargs = "*", desc = "Open daily note" })

					-- :Today
					vim.api.nvim_buf_create_user_command(bufnr, "Today", function()
						vim.cmd("Daily today")
					end, { desc = "Open today's daily note" })

					-- :Tomorrow
					vim.api.nvim_buf_create_user_command(bufnr, "Tomorrow", function()
						vim.cmd("Daily tomorrow")
					end, { desc = "Open tomorrow's daily note" })

					-- :Yesterday
					vim.api.nvim_buf_create_user_command(bufnr, "Yesterday", function()
						vim.cmd("Daily yesterday")
					end, { desc = "Open yesterday's daily note" })
				end
			end
		end,
	})

	vim.lsp.config("markdown_oxide", {
		cmd = { "markdown-oxide" },
		filetypes = { "markdown" },
		root_markers = { ".moxide.toml", ".obsidian", ".git" },
		capabilities = {
			workspace = {
				didChangeWatchedFiles = {
					dynamicRegistration = true,
				},
			},
		},
	})

	vim.lsp.enable("markdown_oxide")
end

return M
