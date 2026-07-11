local M = {}

-- 提取光标下的标识符
local function get_symbol_under_cursor()
	local node = vim.treesitter.get_node()
	if not node then
		return vim.fn.expand("<cword>")
	end

	-- 尝试找到标识符节点
	while node do
		local node_type = node:type()
		if node_type:match("identifier") or node_type:match("name") then
			return vim.treesitter.get_node_text(node, 0)
		end
		node = node:parent()
	end

	return vim.fn.expand("<cword>")
end

-- 执行 ripgrep 搜索（异步）
local function search_symbol(symbol, callback)
	local Job = require("plenary.job")
	local results = {}
	local current_file = vim.fn.expand("%:.")  -- 当前文件相对路径
	local cwd = vim.loop.cwd()  -- 使用 global cwd

	Job:new({
		command = "rg",
		cwd = cwd,  -- 设置工作目录
		args = {
			"--vimgrep",
			"--word-regexp",
			symbol,
			".",  -- 搜索当前目录
		},
		on_exit = function(job, return_val)
			if return_val ~= 0 then
				callback({})
				return
			end

			local output = job:result()
			
			-- 解析输出 (vimgrep 格式: file:line:column:text)
			for _, line in ipairs(output) do
				local file, lnum, col, text = line:match("^(.+):(%d+):(%d+):(.*)$")
				if file and lnum then
					local score = 1

					-- 标准化路径：移除 ./ 或 .\ 前缀
					local file_normalized = file:gsub("^%.[\\/]", "")
					local current_normalized = current_file:gsub("^%.[\\/]", "")

					-- 当前文件加分
					if file_normalized == current_normalized then
						score = score + 10
					end

					table.insert(results, {
						filename = file,
						lnum = tonumber(lnum),
						col = tonumber(col),
						text = text:match("^%s*(.-)%s*$") or text,
						score = score,
					})
				end
			end

			-- 按分数排序：当前文件在前，其他保持原顺序
			table.sort(results, function(a, b)
				return a.score > b.score
			end)

			callback(results)
		end,
	}):start()
end

-- 使用 Telescope 展示结果
local function show_results_in_telescope(symbol, results)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	pickers
		.new({}, {
			prompt_title = string.format("Symbol: %s (%d matches)", symbol, #results),
			finder = finders.new_table({
				results = results,
				entry_maker = function(entry)
					return {
						value = entry,
						display = string.format(
							"%s:%d: %s",
							vim.fn.fnamemodify(entry.filename, ":."),
							entry.lnum,
							entry.text:sub(1, 80)
						),
						ordinal = entry.filename .. " " .. entry.text,
						filename = entry.filename,
						lnum = entry.lnum,
						col = entry.col,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = conf.qflist_previewer({}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection then
						vim.cmd(string.format("edit %s", selection.filename))
						vim.api.nvim_win_set_cursor(0, { selection.lnum, selection.col })
					end
				end)
				return true
			end,
		})
		:find()
end

-- 主入口
function M.go_to_symbol()
	local symbol = get_symbol_under_cursor()
	if symbol == "" then
		vim.notify("No symbol under cursor", vim.log.levels.WARN)
		return
	end

	-- 显示搜索提示
	vim.notify(string.format("Searching for '%s'...", symbol), vim.log.levels.INFO)

	search_symbol(symbol, function(results)
		vim.schedule(function()
			if #results == 0 then
				vim.notify(string.format("No matches found for '%s'", symbol), vim.log.levels.WARN)
			else
				-- 所有结果都用 Telescope
				show_results_in_telescope(symbol, results)
			end
		end)
	end)
end

return M
