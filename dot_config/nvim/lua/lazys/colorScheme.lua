return {
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			local colorscheme = "tokyonight"
			--local colorscheme = "neofusion"
			require("tokyonight").setup({
				-- your configuration comes here
				-- or leave it empty to use the default settings
				style = "moon", -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
				light_style = "day", -- The theme is used when the background is set to light
				transparent = true, -- Enable this to disable setting the background color
				terminal_colors = true, -- Configure the colors used when opening a `:terminal` in Neovim
				styles = {
					-- Style to be applied to different syntax groups
					-- Value is any valid attr-list value for `:help nvim_set_hl`
					comments = { italic = true, bold = true },
					keywords = { italic = true, bold = true },
					--functions = { bold = true },
					variables = { bold = true },
					-- Background styles. Can be "dark", "transparent" or "normal"
					sidebars = "transparent", -- style for sidebars, see below
					floats = "transparent", -- style for floating windows
				},
				sidebars = { "qf", "help", "lualine" }, -- Set a darker background on sidebar-like windows. For example: `["qf", "vista_kind", "terminal", "packer"]`
				day_brightness = 0.3, -- Adjusts the brightness of the colors of the **Day** style. Number between 0 and 1, from dull to vibrant colors
				hide_inactive_statusline = false, -- Enabling this option, will hide inactive windows and replace them with a thin border instead. Should work with the standard **StatusLine** and **LuaLine**.
				dim_inactive = false, -- dims inactive windows
				lualine_bold = true, -- When `true`, section headers in the lualine theme will be bold
			})

			local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)

			if not status_ok then
				vim.notify("colorscheme " .. colorscheme .. " 没有找到！")
				return
			end

			--vim.cmd("highlight! BufferLineSeparatorVisible guifg=#82aaff guibg=NONE")
			--vim.cmd("highlight! BufferLineSeparatorSelected guifg=#82aaff guibg=NONE")
			--vim.cmd("highlight! BufferLineSeparator guifg=#82aaff guibg=NONE")
			--
			--vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })
			--vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE" })
			--
			--vim.cmd("highlight! TabLineFill guifg=None guibg=#171b2e")
			--
			--vim.cmd("highlight! TabLineSel guifg=#aab7f2 guibg=#1f2335")
			--vim.cmd("highlight! TabLineLine guifg=#96a2d6 guibg=#1f2335")
			--
			--
			--vim.cmd("highlight! MatchParen guifg=#1a1b26 guibg=#ff9e64 gui=bold cterm=bold")
			--vim.cmd("highlight! Cursor guifg=#1a1b26 guibg=#7dcfff")
			--vim.api.nvim_set_hl(0, "NormalCursor", { fg = "#1a1b26", bg = "#7dcfff" })
			--vim.api.nvim_set_hl(0, "InsertCursor", { fg = "#222436", bg = "#ffffff" })
			--vim.api.nvim_set_hl(0, "VisualCursor", { fg = "#1a1b26", bg = "#9ece6a" })
			--
			--vim.cmd("highlight! CursorLine guibg=#3b4261")
			--vim.cmd("highlight! DiagnosticUnnecessary guifg=#747da6")
			--vim.cmd("highlight! Comment cterm=bold,italic gui=bold,italic guifg=#747da6")
			--vim.cmd("highlight! LspInlayHint guifg=#6d7594")

		end,
	},
	{
		"xiyaowong/transparent.nvim",
		dependencies = { "folke/tokyonight.nvim" },
		lazy = false,
		priority = 1000,
		--enabled = false,
		config = function()
			require("transparent").setup({
				exclude_groups = {
					"CursorLine",
					"CursorLineNr",
				},
			})

			require("transparent").clear_prefix("BufferLine")
			require("transparent").clear_prefix("NeoTree")
			require("transparent").clear_prefix("lualine")
			require("transparent").clear_prefix("Lsp")
			require("transparent").clear_prefix("Noice")
			require("transparent").clear_prefix("Saga")

			require("transparent").clear("HoverBorder")
			require("transparent").clear("Pmenu")
			require("transparent").clear("NotifyBackground")
		end,
	},
}
