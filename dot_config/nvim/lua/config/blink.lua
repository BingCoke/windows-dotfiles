-- 设置全局默认配置
local blink = require"blink.cmp"

vim.lsp.config("*", {
	capabilities = blink.get_lsp_capabilities(),
})

require("blink.cmp").setup({
	snippets = { preset = "luasnip" },
	keymap = {
		preset = "none",

		-- 插入模式按键
		["<C-j>"] = { "select_next", "fallback" },
		["<C-k>"] = { "select_prev", "fallback" },
		["<C-u>"] = { "scroll_documentation_up", "fallback" },
		["<C-d>"] = { "scroll_documentation_down", "fallback" },
		["<M-s>"] = { "show", "fallback" },
		["<C-e>"] = { "hide", "fallback" },

		-- Tab: 接受补全 或 跳转到下一个 snippet 位置
		["<Tab>"] = {
			function(cmp)
				if cmp.is_menu_visible() then
					return cmp.accept()
				elseif cmp.snippet_active() then
					return cmp.snippet_forward()
				end
			end,
			"fallback",
		},

		-- Shift-Tab: 跳转到上一个 snippet 位置
		["<S-Tab>"] = {
			function(cmp)
				if cmp.snippet_active({ direction = -1 }) then
					return cmp.snippet_backward()
				end
			end,
			"fallback",
		},
	},

	appearance = {
		use_nvim_cmp_as_default = true,
		nerd_font_variant = "mono",
	},

	completion = {
		accept = {
			auto_brackets = {
				enabled = false,
			},
		},
		menu = {
			draw = {
				columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind", gap = 1 } },
			},
			border = "rounded",
		},
		documentation = {
			auto_show = true,
			auto_show_delay_ms = 100,
			window = {
				border = "rounded",
				max_width = 80,
			},
		},
		ghost_text = {
			enabled = false,
		},
	},

	signature = {
		enabled = true,
		window = {
			border = "rounded",
		},
	},

	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
		providers = {
			cmdline = {
				-- ignores cmdline completions when executing shell commands
				enabled = function()
					return vim.fn.getcmdtype() ~= ":" or not vim.fn.getcmdline():match("^[%%0-9,'<>%-]*!")
				end,
			},
		},
	},

	-- Cmdline 模式配置（只有 enabled 和 keymap）
	cmdline = {
		enabled = true,
		keymap = { preset = "inherit" },
		completion = { menu = { auto_show = true } },
	},

	fuzzy = {
		implementation = "rust",
	},
})
