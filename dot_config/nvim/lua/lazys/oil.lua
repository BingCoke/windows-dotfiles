return {
	"stevearc/oil.nvim",
	enabled = true,
	lazy = false,

	dependencies = { "nvim-tree/nvim-web-devicons" },

	config = function()
		local function oil_find_descendant()
			local oil = require("oil")
			local root = oil.get_current_dir()
			if not root then
				vim.notify("Oil: current directory is unavailable", vim.log.levels.WARN)
				return
			end

			local fd = vim.fn.executable("fd") == 1 and "fd" or "fdfind"
			if vim.fn.executable(fd) ~= 1 then
				vim.notify("Oil: install fd to search descendant directories", vim.log.levels.ERROR)
				return
			end

			local pickers = require("telescope.pickers")
			local finders = require("telescope.finders")
			local sorters = require("telescope.config").values
			local actions = require("telescope.actions")
			local action_state = require("telescope.actions.state")

			pickers.new({}, {
				prompt_title = "Oil descendant directories",
				finder = finders.new_oneshot_job({
					fd,
					"--type",
					"d",
					"--hidden",
					"--exclude",
					".git",
					"--absolute-path",
					".",
					root,
				}, {}),
				sorter = sorters.file_sorter({}),
				attach_mappings = function(prompt_bufnr)
					actions.select_default:replace(function()
						local entry = action_state.get_selected_entry()
						actions.close(prompt_bufnr)
						if entry then
							oil.open(vim.trim(entry.value))
						end
					end)
					return true
				end,
			}):find()
		end

		local function oil_pick_ancestor()
			local oil = require("oil")
			local dir = oil.get_current_dir()
			if not dir then
				vim.notify("Oil: current directory is unavailable", vim.log.levels.WARN)
				return
			end

			local ancestors = {}
			for parent in vim.fs.parents(vim.fs.normalize(dir)) do
				ancestors[#ancestors + 1] = parent
			end

			if #ancestors == 0 then
				vim.notify("Oil: no ancestor directory", vim.log.levels.INFO)
				return
			end

			vim.ui.select(ancestors, {
				prompt = "Oil ancestor directory",
				format_item = function(path)
					return vim.fn.fnamemodify(path, ":~")
				end,
			}, function(parent)
				if parent then
					oil.open(parent)
				end
			end)
		end

		require("oil").setup({
			default_file_explorer = true, -- start up nvim with oil instead of netrw
			cleanup_delay_ms = 60000,
			columns = {
				"icon",
				"permissions",
				"size",
				"mtime",
			},
			use_default_keymaps = false,
			watch_for_changes = true,
			keymaps = {
				["g?"] = { "actions.show_help", mode = "n" },
				["<CR>"] = "actions.select",
				["<2-LeftMouse>"] = "actions.select",
				["gd"] = "actions.select",
				["gp"] = { "actions.parent", mode = "n" },
				["<C-p>"] = {
					callback = oil_find_descendant,
					desc = "Find descendant directory",
					mode = "n",
				},
				["gP"] = {
					callback = oil_pick_ancestor,
					desc = "Choose ancestor directory",
					mode = "n",
				},

				["s"] = { "actions.select", opts = { vertical = true } },
				["S"] = { "actions.select", opts = { horizontal = true } },

				["t"] = { "actions.select", opts = { tab = true } },

				["q"] = { "actions.close", mode = "n" },
				["K"] = { "actions.preview", mode = "n" },
				["Y"] = {
					callback = function()
						local oil = require("oil")
						local entry = oil.get_cursor_entry()
						local dir = oil.get_current_dir()
						if entry and dir then
							require("util.copy_relative_path")(vim.fs.joinpath(dir, entry.name))
						end
					end,
					desc = "Copy relative path",
					mode = "n",
				},

				["<C-r>"] = "actions.refresh",

				["_"] = { "actions.open_cwd", mode = "n" },
				["`"] = { "actions.cd", mode = "n" },
				["cd"] = { "actions.cd", mode = "n" },
				["gl"] = { "actions.cd", opts = { scope = "win" }, mode = "n" },
				["gs"] = { "actions.change_sort", mode = "n" },
				["gx"] = "actions.open_external",
				["g."] = { "actions.toggle_hidden", mode = "n" },
				["H"] = { "actions.toggle_hidden", mode = "n" },
				["g\\"] = { "actions.toggle_trash", mode = "n" },
			},
			delete_to_trash = true,
			float = {
				border = "rounded", -- 将边框样式设置为 "rounded"
			},
			view_options = {
				show_hidden = true,
			},
			skip_confirm_for_simple_edits = true,
		})

		vim.api.nvim_create_autocmd({ "User", "BufEnter", "WinEnter" }, {
			pattern = { "OilEnter", "*" },
			group = vim.api.nvim_create_augroup("OilAutoLcd", { clear = true }),
			callback = function(args)
				local bufnr = args.data and args.data.buf or args.buf or vim.api.nvim_get_current_buf()

				if vim.bo[bufnr].filetype ~= "oil" then
					return
				end

				local dir = require("oil").get_current_dir(bufnr)

				if not dir then
					return
				end

				vim.cmd.lcd(vim.fn.fnameescape(dir))
			end,
		})

		-- opens parent dir over current active window
		vim.keymap.set({ "n" }, "-", function()
			require("oil").toggle_float(vim.fn.getcwd(-1, -1))
		end, { desc = "Open global cwd" })

		vim.keymap.set({ "n" }, "_", function()
			require("oil").open(vim.fn.getcwd(-1, -1))
		end, { desc = "Open global cwd" })

		vim.keymap.set({ "n", "i", "t" }, "<M-v>", function()
			local dir = nil

			if vim.bo.buftype == "terminal" then
				dir = vim.fn.getcwd(0, 0)
			end

			require("oil").open(dir)
		end, { desc = "Oil: toggle buffer" })

		vim.keymap.set({ "n", "i", "t" }, "<M-f>", function()
			local dir = nil

			if vim.bo.buftype == "terminal" then
				dir = vim.fn.getcwd(0, 0)
			end

			require("oil").toggle_float(dir)
		end, { desc = "Oil: toggle float" })
	end,
}
