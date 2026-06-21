vim.g.mapleader = " "
vim.g.maplocalleader = " "

--local map = vim.api.nvim_set_keymap
local map = vim.keymap.set
-- 复用 opt 参数
local opt = { noremap = true, silent = true }

map("i", "<c-`>", "`", opt)

-- 取消 s 默认功能
map("n", "s", "", opt)

-- ctrl+l 回到正常模式
vim.keymap.set({ "i", "v" }, "<C-l>", "<esc>", { noremap = true, silent = true })
vim.keymap.set({ "t" }, "<C-l>", "<c-\\><c-n>", { noremap = true, silent = true })
-- 插入模式
vim.keymap.set({ "i" }, "<C-v>", "<C-r>+", { noremap = true, silent = true })
vim.keymap.set("c", "<C-v>", function()
	local text = vim.fn.getreg("+")
	vim.api.nvim_feedkeys(text, "n", true)
end, { noremap = true, silent = true })

map("v", "<c-c>", '"+y', opt)

local function copy_file_line_reference()
	local path = vim.fn.expand("%:p")
	if path == "" then
		vim.notify("No file path for current buffer", vim.log.levels.WARN)
		return
	end

	path = path:gsub("\\", "/")

	local start_line = vim.fn.line("v")
	local end_line = vim.fn.line(".")
	if vim.fn.mode() == "n" then
		start_line = vim.fn.line(".")
		end_line = start_line
	end

	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end

	local line_text = start_line == end_line and tostring(start_line) or (start_line .. "-" .. end_line)
	local text = string.format("%s line %s", path, line_text)

	vim.fn.setreg("+", text)
end

map("n", "<M-c>", copy_file_line_reference, opt)
map("v", "<M-c>", function()
	copy_file_line_reference()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
end, opt)

vim.keymap.set({ "n", "i", "v", "c", "t" }, "<F13>", "<Nop>", { noremap = true, silent = true })

map({ "n", "v", "i" }, "<c-a>", "<esc>ggVG", opt)

-- 关闭当前
map("n", "<leader>sc", "<C-w>c", opt)

map("n", "<M-d>", "<C-w>c", opt)
map("i", "<M-d>", "<C-w>c", opt)

-- 关闭其他
map("n", "<leader>so", "<C-w>o", opt)

-- 左右比例控制

map("n", "<esc>", "<cmd>noh<cr><esc>", opt)
map("i", "<esc>", "<cmd>noh<cr><esc>", opt)

map("n", "<leader>w", "<cmd>w<cr><esc>", opt)

-- 上下比例控制
map("n", "<C-Down>", "<cmd>resize -2<CR>", opt)
map("n", "<C-Up>", "<cmd>resize +2<CR>", opt)
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", opt)
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", opt)

-- Terminal相关
-- 打开terminal
map("n", "<leader>h", function()
	vim.cmd("sp | terminal")
	vim.cmd("startinsert")
end, opt)

map("n", "<leader>v", function()
	vim.cmd("vsp | terminal")
	vim.cmd("startinsert")
end, opt)

-- visual模式下缩进代码
map("v", "<", "<gv", opt)
map("v", ">", ">gv", opt)

-- 上下移动选中文本
map("v", "<M-j>", "<cmd>move '>+1<CR>gv-gv", opt)
map("v", "<M-k>", "<cmd>move '<-2<CR>gv-gv", opt)

-- 上下滚动浏览
map("n", "<C-j>", "5j", opt)
map("n", "<C-k>", "5k", opt)
map("v", "<C-j>", "5j", opt)
map("v", "<C-k>", "5k", opt)

-- ctrl u / ctrl + d  只移动9行，默认移动半屏
map("n", "<C-u>", "10k", opt)
map("n", "<C-d>", "10j", opt)
map("v", "<C-u>", "10k", opt)
map("v", "<C-d>", "10j", opt)
-- 设置退出并,保存

map("n", "<leader>q", "<cmd>qa<CR>", opt)
map("n", "<leader>i", "<cmd>qa<CR>", opt)
map("n", "<leader>W", "<cmd>w !sudo tee %<CR>", {})

-- 设置插件快捷键
local pluginKeys = {}
--translate

-- 设置文件搜索
-- Telescope
-- 查找文件
-- dap

map("n", "<c-w>", "<c-w>w", opt)

-- 跳转到下一个错误（仅 ERROR）
vim.keymap.set("n", "]e", function()
	vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = false })
end, opt)

-- 跳转到上一个错误（仅 ERROR）
vim.keymap.set("n", "[e", function()
	vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = false })
end, opt)

-- 下一个诊断（所有级别）
vim.keymap.set("n", "]g", function()
	vim.diagnostic.jump({ count = 1, float = false })
end, opt)

-- 上一个诊断（所有级别）—— 注意这里修正为 count = -1
vim.keymap.set("n", "[g", function()
	vim.diagnostic.jump({ count = -1, float = false })
end, { desc = "Previous Diagnostic" })

-- 使用vscode打开当前文件
vim.keymap.set("n", "<leader>cc", function()
	vim.fn.jobstart({ "code", "-a", vim.loop.cwd(), vim.fn.expand("%:p") })
end, {
	desc = "open vscode in current buffer file",
	noremap = true,
	silent = true,
})

return pluginKeys
