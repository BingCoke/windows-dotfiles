return {
	{
		"BingCoke/fre.nvim",
		lazy = false,
		branch = "refactor/instance-decomposition",
		dependencies = { "nvim-tree/nvim-web-devicons" },

		config = function()
			local fre = require("fre")
			local actions = require("fre.actions")
			local current = { position = "current" }
			local left = { position = "left", size = 0.25 }
			local float = { position = "float", width = 0.6, height = 0.8, border = "rounded" }
			local root_instance, root_cursor

			local function stop_insert()
				if vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
					vim.cmd.stopinsert()
				end
			end

			local function current_file()
				if vim.bo.buftype ~= "" then
					return nil
				end
				local name = vim.api.nvim_buf_get_name(0)
				return name ~= "" and vim.fs.normalize(name) or nil
			end

			local function contextual_target()
				if vim.bo.buftype == "terminal" then
					return vim.fn.getcwd(0, 0), nil
				end
				local file = current_file()
				return file and vim.fs.dirname(file) or vim.fn.getcwd(), file
			end

			local function view_of(instance, tabpage)
				return instance and fre.view.inspect(instance, tabpage) or nil
			end

			local function remember_cursor(instance, tabpage)
				if instance ~= root_instance then
					return
				end
				local view = view_of(instance, tabpage)
				if not view then
					return
				end
				local row = vim.api.nvim_win_get_cursor(view.winid)[1]
				local ok, entry = pcall(instance.get_entry, instance, row)
				root_cursor = ok and entry and entry.relative_path or nil
			end

			local function hide(instance, tabpage)
				if not view_of(instance, tabpage) then
					return false
				end
				remember_cursor(instance, tabpage)
				instance:hidden(tabpage)
				return true
			end

			local function discard_root()
				if root_instance and fre.get_instance_by_id(root_instance.id) == root_instance then
					if vim.api.nvim_buf_is_valid(root_instance.bufnr) and vim.bo[root_instance.bufnr].modified then
						error("fre: root instance has unsaved filesystem edits")
					end
					root_instance:destroy()
				end
				root_instance, root_cursor = nil, nil
			end

			local function root_for(root)
				root = vim.fs.normalize(root)
				if
					root_instance
					and fre.get_instance_by_id(root_instance.id) == root_instance
					and vim.fs.normalize(root_instance.root) == root
				then
					return root_instance
				end
				discard_root()
				root_instance = fre.new({ root = root, gc = { group = "root" } })
				return root_instance
			end

			local function cd_to_root(instance)
				if root_instance ~= instance then
					discard_root()
					fre.set_group(instance, "root")
					root_instance, root_cursor = instance, nil
				end
				vim.cmd("cd " .. vim.fn.fnameescape(instance.root))
			end

			local function source_view(ctx)
				local view = assert(view_of(ctx.instance, ctx.tabpage), "fre: source View is no longer active")
				remember_cursor(ctx.instance, ctx.tabpage)
				return view
			end

			local function origin_for(view)
				local origin = view.origin_winid
				if
					not origin
					or not vim.api.nvim_win_is_valid(origin)
					or vim.api.nvim_win_get_config(origin).relative ~= ""
				then
					error("fre: explorer origin window is no longer valid")
				end
				return origin
			end

			local function file_target(view)
				local origin = view.origin_winid
				if not origin or not vim.api.nvim_win_is_valid(origin)
					or vim.api.nvim_win_get_config(origin).relative ~= "" then
					return nil
				end
				if fre.get_instance(vim.api.nvim_win_get_buf(origin)) then
					return nil
				end
				return origin
			end

			local function select(ctx)
				local view = source_view(ctx)
				local directory = ctx.row_kind == "navigation" or (ctx.entry and ctx.entry.kind == "directory")
				if directory or view.layout.position ~= "float" then
					return actions.select(ctx)
				end
				local target_winid = file_target(view)
				if not target_winid then
					return actions.select(ctx)
				end
				return actions.select(ctx, {
					target_winid = target_winid,
					hide_source = view.layout.position == "float",
				})
			end

			local function split_select(position)
				return function(ctx)
					local view = source_view(ctx)
					return actions.split_select(ctx, {
						layout = { position = position, size = 0.5 },
						anchor_winid = view.layout.position == "current" and ctx.winid or origin_for(view),
						hide_source = view.layout.position == "float",
					})
				end
			end

			local function tab_select(ctx)
				local view = source_view(ctx)
				return actions.tab_select(ctx, { hide_source = view.layout.position == "float" })
			end

			local function select_parent()
				local instance = fre.get_instance()
				local winid = vim.api.nvim_get_current_win()
				local view = view_of(instance)
				if not view or view.winid ~= winid then
					return false
				end
				stop_insert()
				remember_cursor(instance, vim.api.nvim_win_get_tabpage(winid))
				vim.api.nvim_win_set_cursor(winid, { 1, 0 })
				actions.select(actions.context())
				return true
			end

			fre.setup({
				default_file_explorer = true,
				hidden_file = true,
				skip_confirm_for_simple_edits = true,
				auto_expand_single_directory = true,
				layout = left,
				gc = { ttl_ms = 0, groups = { default = 10, root = 1 } },
				mapping = {
					n = {
						["<CR>"] = select,
						["<2-LeftMouse>"] = select,
						["gd"] = select,
						["s"] = split_select("right"),
						["S"] = split_select("bottom"),
						["t"] = tab_select,
						["<C-r>"] = actions.refresh,
						["H"] = actions.toggle_hidden_file,
						["q"] = function(ctx)
							hide(ctx.instance, ctx.tabpage)
						end,
						["gp"] = actions.jump_to_path,
						["Y"] = function(ctx)
							if ctx.entry then
								require("util.copy_relative_path")(ctx.entry.absolute_path)
							end
						end,
						["gx"] = function(ctx)
							if ctx.entry then
								vim.ui.open(ctx.entry.absolute_path)
							end
						end,
						["cd"] = function(ctx)
							cd_to_root(ctx.instance)
						end,
					},
				},
				window = { options = { cursorline = true } },
			})

			local function reveal(instance, file)
				local relative = file and vim.fs.relpath(instance.root, vim.fs.normalize(file))
				if relative then
					instance:when_ready(function(err)
						if not err and view_of(instance) then
							pcall(instance.reveal, instance, relative)
						end
					end)
				end
			end

			local function open(instance, layout, file)
				stop_insert()
				local _, winid = instance:open(layout)
				reveal(instance, file)
				return winid
			end

			local function close_focused()
				local instance = fre.get_instance()
				local tabpage = vim.api.nvim_get_current_tabpage()
				local view = view_of(instance, tabpage)
				if view and view.winid == vim.api.nvim_get_current_win() then
					hide(instance, tabpage)
				end
			end

			local function fresh_command(root_resolver, layout, follow)
				return function()
					local root = root_resolver()
					local file = follow and current_file() or nil
					close_focused()
					open(fre.new({ root = root }), layout, file)
				end
			end

			local function fresh_context(layout)
				return function()
					close_focused()
					local root, file = contextual_target()
					open(fre.new({ root = root }), layout, file)
				end
			end

			local function open_parent()
				if not select_parent() then
					local root, file = contextual_target()
					open(fre.new({ root = root }), current, file)
				end
			end

			local function singleton_float(follow)
				return function()
					local tabpage = vim.api.nvim_get_current_tabpage()
					local focused = fre.get_instance()
					local focused_view = view_of(focused, tabpage)
					if
						focused_view
						and focused_view.winid == vim.api.nvim_get_current_win()
						and focused_view.layout.position == "float"
					then
						hide(focused, tabpage)
						return
					end
					local file = follow and current_file() or nil
					local instance = root_for(vim.fn.getcwd())
					local active = view_of(instance, tabpage)
					if active and active.layout.position == "float" then
						hide(instance, tabpage)
						return
					end
					local winid = open(instance, float, file)
					if not follow and not active and root_cursor then
						pcall(instance.set_cursor_to_path, instance, root_cursor, winid)
					end
				end
			end

			local function map(modes, lhs, rhs, desc)
				vim.keymap.set(modes, lhs, rhs, { silent = true, desc = desc })
			end

			local function global_cwd()
				return vim.fn.getcwd(-1, -1)
			end

			map("n", "-", fresh_command(global_cwd, float, false), "Fre: open new global cwd float")
			map("n", "_", fresh_command(global_cwd, current, false), "Fre: open new global cwd instance")
			map({ "n", "i" }, "<M-v>", open_parent, "Fre: open new parent instance")
			map({ "n", "i" }, "<M-f>", fresh_context(float), "Fre: open new contextual float")
			map("n", "<M-m>", fresh_command(vim.fn.getcwd, left, false), "Fre: open new cwd left")
			map("n", "<M-M>", fresh_command(vim.fn.getcwd, left, true), "Fre: open new cwd left and reveal file")
			map("n", "\\", singleton_float(false), "Fre: toggle cwd singleton float")
			map("n", "|", singleton_float(true), "Fre: toggle cwd singleton float and reveal file")
		end,
	},
}
