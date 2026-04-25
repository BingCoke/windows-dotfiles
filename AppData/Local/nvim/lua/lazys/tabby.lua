local highlights = require("telescope.pickers.highlights")
return {
	"nanozuki/tabby.nvim",

	config = function()
		vim.api.nvim_set_keymap("n", "<leader>oa", "<cmd>tabnew<CR>", { noremap = true })
		vim.api.nvim_set_keymap("n", "<leader>oo", "<cmd>tabonly<CR>", { noremap = true })

		vim.keymap.set("n", "<leader>of", "<cmd>tabnew %<cr>", { noremap = true })

		vim.api.nvim_set_keymap("n", "<M-w>", ":tabclose<CR>", { noremap = true })

		vim.api.nvim_set_keymap("n", "<C-l>", ":tabn<CR>", { noremap = true })
		vim.api.nvim_set_keymap("n", "<C-h>", ":tabp<CR>", { noremap = true })

		-- move current tab to previous position
		vim.api.nvim_set_keymap("n", "<M-i>", ":-tabmove<CR>", { noremap = true })
		-- move current tab to next position
		vim.api.nvim_set_keymap("n", "<M-o>", ":+tabmove<CR>", { noremap = true })

		vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
		-- split window vertically
		vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
		for i = 1, 8, 1 do
			vim.keymap.set("n", "<leader>" .. i, i .. "gt")
		end

		local theme = {
			fill = "TabLineFill",
			-- Also you can do this: fill = { fg='#f2e9de', bg='#907aa9', style='italic' }
			head = "TabLine",
			current_tab = "TabLineSel",
			tab = "TabLine",
			win = "TabLine",
			tail = "TabLine",
		}

		local function get_special_buf_name(bufid)
			local ft = vim.bo[bufid].filetype
			if ft == "TelescopePrompt" then
				return "telescope"
			end
			if ft == "NvimTree" then
				return "󰙅 Files"
			end
			if ft == "oil" then
				local path = vim.api.nvim_buf_get_name(bufid):gsub("^oil://", ""):gsub("/$", "")
				return "󰉋 " .. vim.fn.fnamemodify(path, ":t") .. "/"
			end
			if ft == "fugitive" then
				return " Git"
			end
			if ft == "lazy" then
				return "󰒲 Lazy"
			end
			-- 返回 nil 走默认逻辑
		end

		require("tabby").setup({
			option = {
				tab_name = {
					-- tab 名称的 override：取当前 window 的 buf，特殊处理
					name_fallback = function(tabid)
						local winid = vim.api.nvim_tabpage_get_win(tabid)
						local bufid = vim.api.nvim_win_get_buf(winid)
						local r = get_special_buf_name(bufid)
							or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufid), ":t")
						return r == "" and "none" or r
					end,
				},
				buf_name = {
					mode = "unique", -- or 'relative', 'tail', 'shorten'
					name_fallback = function(bufid)
						return "[No Name]"
					end,
					override = nil,
				},
			},
			line = function(line)
				local function extract_fg(groups, fallback)
					for _, name in ipairs(groups) do
						local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
						if ok and hl.fg then
							return string.format("#%06x", hl.fg)
						end
					end
					return fallback
				end

				local function get_tab_bg(hl_name)
					local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = hl_name, link = false })
					if ok and hl.bg then
						return string.format("#%06x", hl.bg)
					end
					return "#1f2335"
				end

				local diag_colors = {
					error = extract_fg({ "DiagnosticError", "LspDiagnosticsDefaultError", "DiffDelete" }, "#e32636"),
					warn = extract_fg({ "DiagnosticWarn", "LspDiagnosticsDefaultWarning", "DiffText" }, "#ffa500"),
				}

				local signs = {
					[vim.diagnostic.severity.ERROR] = { icon = " ", fg = diag_colors.error },
					[vim.diagnostic.severity.WARN] = { icon = " ", fg = diag_colors.warn },
				}

				local function get_buf_diagnostic(bufnr)
					local counts = vim.diagnostic.count(bufnr)
					if (counts[vim.diagnostic.severity.ERROR] or 0) > 0 then
						return signs[vim.diagnostic.severity.ERROR]
					elseif (counts[vim.diagnostic.severity.WARN] or 0) > 0 then
						return signs[vim.diagnostic.severity.WARN]
					end
					return nil
				end

				local function tab_modified(tab)
					for _, win in ipairs(tab.wins().wins) do
						if win.buf().is_changed() then
							return "●"
						end
					end
					return ""
				end

				local theme = {
					fill = "TabLineFill",
					head = "TabLine",
					current_tab = "TabLineSel",
					tab = "TabLine",
					win = "TabLine",
					tail = "TabLine",
				}

				return {
					{ " ", hl = theme.head },
					line.tabs().foreach(function(tab)
						local hl = tab.is_current() and theme.current_tab or theme.tab
						local bg = get_tab_bg(hl)
						local win = vim.api.nvim_tabpage_get_win(tab.id)
						local buf = vim.api.nvim_win_get_buf(win)
						local diag = get_buf_diagnostic(buf)
						return {
							tab.number(),
							tab.name(),
							diag and { diag.icon .. "", hl = { fg = diag.fg, bg = bg } } or "",
							tab_modified(tab),
							tab.close_btn(" "),
							hl = hl,
							margin = " ",
						}
					end),
					line.spacer(),
					hl = theme.fill,
				}
			end,
			-- option = {}, -- setup modules' option,
		})
	end,
}
