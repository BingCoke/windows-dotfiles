local lsp = require("lsp.lsp")

local M = {}

function M.setup()
	-- 确保 capabilities 包含 dynamicRegistration
	local capabilities = vim.tbl_deep_extend("force", lsp.capabilities, {
		workspace = {
			didChangeWatchedFiles = {
				dynamicRegistration = true,
			},
		},
	})

	vim.lsp.config("markdown_oxide", {
		cmd = { "markdown-oxide" },
		filetypes = { "markdown" },
		root_markers = { ".moxide.toml", ".obsidian", ".git" },
		capabilities = capabilities,
		on_attach = function(client, bufnr)
			-- 调用你的通用 on_attach
			lsp.on_attach(client, bufnr)

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
		end,
	})
	vim.lsp.enable("markdown_oxide")
end

return M
