return {
	"nvim-orgmode/orgmode",
	event = "VeryLazy",
	keys = {
		{ "<leader>oa", "<cmd>Org agenda<cr>", desc = "Org agenda" },
		{ "<leader>oc", "<cmd>Org capture<cr>", desc = "Org capture" },
		{ "<leader>oi", "<cmd>edit ~/org/inbox.org<cr>", desc = "Org inbox" },
		{ "<leader>ot", "<cmd>edit ~/org/tasks.org<cr>", desc = "Org tasks" },
		{ "<leader>on", "<cmd>edit ~/org/notes.org<cr>", desc = "Org notes" },
		{ "<leader>od", "<cmd>edit ~/org/someday.org<cr>", desc = "Org someday" },
		{
			"<leader>os",
			function()
				local ok, builtin = pcall(require, "telescope.builtin")
				if not ok then
					vim.notify("Telescope is not available", vim.log.levels.WARN)
					return
				end

				builtin.live_grep({ cwd = vim.fn.expand("~/org") })
			end,
			desc = "Search org notes",
		},
	},
	config = function()
		require("orgmode").setup({
			-- Keep agenda focused on active root org files; archive stays searchable but out of the agenda scan.
			org_agenda_files = "~/org/*.org",
			org_default_notes_file = "~/org/inbox.org",
			org_archive_location = "~/org/archive/archive.org::",
			org_todo_keywords = { "TODO(t)", "NEXT(n)", "WAITING(w)", "SOMEDAY(s)", "|", "DONE(d)", "CANCELLED(c)" },
			org_log_done = "time",
			org_log_into_drawer = "LOGBOOK",
			org_capture_templates = {
				t = {
					description = "Todo -> inbox",
					template = "* TODO %?\n  %U",
					target = "~/org/inbox.org",
				},
				i = {
					description = "Idea / quick note -> inbox",
					template = "* %?\n  %U",
					target = "~/org/inbox.org",
				},
				k = {
					description = "Knowledge / pitfall -> notes",
					template = "* %^{Title}\n  %U\n\n  %?",
					target = "~/org/notes.org",
				},
				s = {
					description = "Someday -> someday",
					template = "* SOMEDAY %?\n  %U",
					target = "~/org/someday.org",
				},
			},
			org_agenda_custom_commands = {
				n = {
					description = "All open tasks",
					types = {
						{
							type = "tags_todo",
							org_agenda_overriding_header = "All open tasks",
							org_agenda_sorting_strategy = { "todo-state-up", "priority-down" },
						},
					},
				},
				w = {
					description = "Work tasks",
					types = {
						{
							type = "tags_todo",
							match = "work",
							org_agenda_overriding_header = "Work tasks",
							org_agenda_sorting_strategy = { "todo-state-up", "priority-down" },
						},
					},
				},
				s = {
					description = "Study tasks",
					types = {
						{
							type = "tags_todo",
							match = "study",
							org_agenda_overriding_header = "Study tasks",
							org_agenda_sorting_strategy = { "todo-state-up", "priority-down" },
						},
					},
				},
				l = {
					description = "Life tasks",
					types = {
						{
							type = "tags_todo",
							match = "life",
							org_agenda_overriding_header = "Life tasks",
							org_agenda_sorting_strategy = { "todo-state-up", "priority-down" },
						},
					},
				},
				r = {
					description = "Review tasks",
					types = {
						{
							type = "tags_todo",
							match = "review",
							org_agenda_overriding_header = "Review tasks",
							org_agenda_sorting_strategy = { "todo-state-up", "priority-down" },
						},
					},
				},
			},
		})

		-- Experimental LSP support
		vim.lsp.enable("org")
	end,
}
