return {

	"swaits/zellij-nav.nvim",
	lazy = true,
	enabled = false,
	event = "VeryLazy",
	config = function()
		require("zellij-nav").setup()

		local function nav(short_direction, direction, action)
			local t0 = vim.uv.hrtime()

			if not action then
				action = "move-focus"
			end

			if action ~= "move-focus" and action ~= "move-focus-or-tab" then
				error("invalid action: " .. action)
			end

			local cur_winnr = vim.fn.winnr()
			local t1 = vim.uv.hrtime()

			vim.api.nvim_command("wincmd " .. short_direction)
			local t2 = vim.uv.hrtime()

			local new_winnr = vim.fn.winnr()
			local t3 = vim.uv.hrtime()

			local at_edge = cur_winnr == new_winnr
			local spawn_elapsed_ms = nil

			if at_edge then
				local t_spawn = vim.uv.hrtime()
				vim.fn.jobstart({ "zellij", "action", action, direction }, {
					detach = true,
					on_exit = function(_, code)
						if code ~= 0 then
							vim.schedule(function()
								vim.notify("[nav] zellij action exited with code " .. code, vim.log.levels.WARN)
							end)
						end
					end,
				})
				spawn_elapsed_ms = (vim.uv.hrtime() - t_spawn) / 1e6
			end

			local total_ms = (vim.uv.hrtime() - t0) / 1e6
			local msg = string.format(
				"[nav] %s(%s) total=%.3fms | winnr=%.3fms wincmd=%.3fms winnr2=%.3fms | at_edge=%s spawn_jobstart=%s",
				action,
				direction,
				total_ms,
				(t1 - t0) / 1e6,
				(t2 - t1) / 1e6,
				(t3 - t2) / 1e6,
				tostring(at_edge),
				spawn_elapsed_ms and string.format("%.3fms", spawn_elapsed_ms) or "n/a"
			)
			vim.notify(msg, vim.log.levels.INFO)
		end
		local M = {}

		function M.up()
			nav("k", "up", nil)
		end

		function M.down()
			nav("j", "down", nil)
		end

		function M.right()
			nav("l", "right", nil)
		end

		function M.left()
			nav("h", "left", nil)
		end

		function M.up_tab()
			nav("k", "up", "move-focus-or-tab")
		end

		function M.down_tab()
			nav("j", "down", "move-focus-or-tab")
		end

		function M.right_tab()
			nav("l", "right", "move-focus-or-tab")
		end

		function M.left_tab()
			nav("h", "left", "move-focus-or-tab")
		end
		local map = vim.keymap.set
		map({ "n" }, "<m-h>", function()
			local start = vim.uv.hrtime()
			M.left()
			local elapsed_ms = (vim.uv.hrtime() - start) / 1e6
			vim.notify(string.format("[require] %-24s %.3f ms", "left", elapsed_ms), vim.log.levels.INFO)
		end, { desc = "navigate left or tab" })
		map({ "n" }, "<m-j>", "<cmd>ZellijNavigateDown<cr>", { desc = "navigate down" })
		map({ "n" }, "<m-k>", "<cmd>ZellijNavigateUp<cr>", { desc = "navigate up" })
		map({ "n" }, "<M-l>", function()
			local start = vim.uv.hrtime()
			M.right()
			local elapsed_ms = (vim.uv.hrtime() - start) / 1e6
			vim.notify(string.format("[require] %-24s %.3f ms", "right", elapsed_ms), vim.log.levels.INFO)
		end, { desc = "navigate right or tab" })
	end,
	keys = {},
	opts = {},
}
