local M = {}

M.setup = function()
	local vue_language_server_path = vim.fn.expand("$MASON/packages")
		.. "/vue-language-server"
		.. "/node_modules/@vue/language-server"

	local tsserver_filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" }
	local vue_plugin = {
		name = "@vue/typescript-plugin",
		location = vue_language_server_path,
		languages = { "vue" },
		configNamespace = "typescript",
	}

	local ts_ls_config = {
		init_options = {
			plugins = {
				vue_plugin,
			},
		},
		filetypes = tsserver_filetypes,
	}

	vim.lsp.config("vtsls", {
		filetypes = tsserver_filetypes,
		settings = {
			vtsls = {
				tsserver = {
					globalPlugins = {
						vue_plugin,
						{
							name = "typescript-svelte-plugin",
							location = vim.fn.stdpath("data") .. "/mason/packages/svelte-language-server",
							languages = { "svelte" },
							configNamespace = "typescript",
							enableForWorkspaceTypeScriptVersions = true,
						},
					},
					preferences = {
						includeInlayFunctionLikeReturnTypeHints = false,
					},
				},
			},
			typescript = {
				inlayHints = {
					parameterNames = { enabled = "all" },
					propertyDeclarationTypes = { enabled = true },
					functionLikeReturnTypes = { enabled = true },
					enumMemberValues = { enabled = true },
					parameterTypes = { enabled = true },
					variableTypes = { enabled = true },
				},
			},
		},
	})

	vim.lsp.config("svelte", {
		settings = {},
	})

	vim.lsp.config("tsgo", {})
	vim.lsp.config("ts_ls", ts_ls_config)

	vim.lsp.enable("vue_ls")
	vim.lsp.enable("svelte")
	--vim.lsp.enable("tsgo")
	vim.lsp.enable("ts_ls")
	--vim.lsp.enable("vtsls")
end

return M
