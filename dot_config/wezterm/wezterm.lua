local wezterm = require("wezterm")

local config = {}

config.term = "xterm-256color"
local act = wezterm.action

config.window_close_confirmation = "NeverPrompt"

config.default_prog = { "nu" }

config.color_scheme = "tokyonight-storm"

config.window_decorations = "RESIZE"

config.window_background_opacity = 0.78

config.font = wezterm.font_with_fallback({
	"IntoneMono Nerd Font Mono",
})

config.background = {}

config.font_size = 16

config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = true

config.colors = {}
config.colors.tab_bar = {
	background = "rgba(41, 46, 66, 0.8)",
	active_tab = {
		bg_color = "rgba(41, 46, 66, 0.85)", -- 85% 不透明度
		fg_color = "#7aa2f7", -- 文字颜色保持不透明
	},
	inactive_tab = {
		bg_color = "rgba(41, 46, 66, 0.85)", -- 65% 不透明度，更透明一些
		fg_color = "#787c99",
	},
	inactive_tab_hover = {
		bg_color = "rgba(59, 66, 97, 0.85)", -- #3b4261 转换为 RGB(59,66,97)
		fg_color = "#c0caf5",
	},
	new_tab = {
		bg_color = "rgba(41, 46, 66, 0.85)",
		fg_color = "#7aa2f7",
	},
	new_tab_hover = {
		bg_color = "rgba(122, 162, 247, 0.8)", -- #7aa2f7 转换为 RGB(122,162,247)
		fg_color = "#1a1b26",
	},
}

config.disable_default_key_bindings = true

config.keys = {
	{
		key = "F13",
		action = wezterm.action.Nop,
	},
	{ key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
	{ key = "q", mods = "CTRL", action = act.CloseCurrentTab({ confirm = false }) },

	{
		key = "v",
		mods = "CTRL",
		action = wezterm.action.SendKey({ key = "v", mods = "CTRL" }),
	},
	{
		key = "v",
		mods = "CTRL|SHIFT",
		action = wezterm.action.PasteFrom("Clipboard"),
	},

	-- new OS window (launch --type=os-window)
	{ key = "Enter", mods = "CTRL|SHIFT", action = act.SpawnWindow },
	-- new tab (launch --type=tab)
	{ key = "Enter", mods = "CTRL", action = act.SpawnTab("CurrentPaneDomain") },
	-- new_tab (ctrl+alt+enter, kitty 原本无cwd)
	{ key = "Enter", mods = "CTRL|ALT", action = act.SpawnTab("DefaultDomain") },
	-- next_tab / previous_tab
	{ key = "l", mods = "CTRL|ALT", action = act.ActivateTabRelative(1) },
	{ key = "h", mods = "CTRL|ALT", action = act.ActivateTabRelative(-1) },
	-- move_tab_forward / move_tab_backward
	{ key = "j", mods = "CTRL|ALT", action = act.MoveTabRelative(1) },
	{ key = "k", mods = "CTRL|ALT", action = act.MoveTabRelative(-1) },
	-- goto_tab 1~9
	{ key = "1", mods = "CTRL", action = act.ActivateTab(0) },
	{ key = "2", mods = "CTRL", action = act.ActivateTab(1) },
	{ key = "3", mods = "CTRL", action = act.ActivateTab(2) },
	{ key = "4", mods = "CTRL", action = act.ActivateTab(3) },
	{ key = "5", mods = "CTRL", action = act.ActivateTab(4) },
	{ key = "6", mods = "CTRL", action = act.ActivateTab(5) },
	{ key = "7", mods = "CTRL", action = act.ActivateTab(6) },
	{ key = "8", mods = "CTRL", action = act.ActivateTab(7) },
	{ key = "9", mods = "CTRL", action = act.ActivateTab(8) },
}

config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
	-- 左键释放时完成选择并复制到系统剪贴板
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = act.CompleteSelectionOrOpenLinkAtMouseCursor("ClipboardAndPrimarySelection"),
	},
	-- 左键拖拽时扩展选择区域（配合上面的释放复制）
	{
		event = { Drag = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = act.ExtendSelectionToMouseCursor("Cell"),
	},
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = act.PasteFrom("Clipboard"),
	},
}

config.swallow_mouse_click_on_window_focus = true
-- shift按住之后可以进行文本选择
config.bypass_mouse_reporting_modifiers = "SHIFT"

config.window_padding = {
	left = 2,
	right = 2,
	top = 0,
	bottom = 0,
}

return config
