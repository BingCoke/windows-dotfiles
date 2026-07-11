local lsp = require("lsp.lsp")

local M = {}

function M.setup()
	-- 1. 先配置 iwes LSP（带 capabilities 和 on_attach）
	vim.lsp.config("iwes", {
		cmd = { "iwes" },
		filetypes = { "markdown" },
		root_markers = { ".iwe" },
		capabilities = lsp.capabilities,
		on_attach = lsp.on_attach,
	})
	vim.lsp.enable("iwes")

	-- 2. 配置 iwe.nvim 插件（它会创建 autocmd 调用 vim.lsp.start）
	require("iwe").setup({
		mappings = {
			enable_markdown_mappings = true,
			enable_picker_keybindings = false,
			enable_lsp_keybindings = false,
			enable_preview_keybindings = false,
			leader = "<leader>",
			localleader = "<localleader>",
		},
		telescope = {
			enabled = true,
			setup_config = false, -- 不让它改 telescope 配置
			load_extensions = { "ui-select", "emoji" },
		},
	})
end
