# Noctalia GTK/Qt 主题

桌面 profile 已经安装 GTK、Qt5 和 Qt6 的主题支持：

```text
adw-gtk3
qt5ct
qt6ct
nwg-look
```

Noctalia 负责根据当前主题生成颜色文件。Home Manager 只负责安装主题工具和提供 Qt6 默认环境变量。

## 首次配置

在 Noctalia 中启用内置模板：

```text
GTK 3
GTK 4
Qt
```

如果使用配置文件，等价设置为：

```toml
[theme.templates]
enable_builtin_templates = true
builtin_ids = ["gtk3", "gtk4", "qt"]
```

不要让 Home Manager 或其他配置工具静态管理 Noctalia 运行时生成的颜色文件。

首次配置 GTK 时运行：

```bash
nwg-look
```

选择 `adw-gtk3` 并应用。不要在 `nwg-look` 中启用 GTK4 主题；如果以前配置过 GTK4 主题，先使用 `Preferences -> Clear` 清除旧的 GTK4 覆盖，让 Noctalia 的 GTK4 CSS 接管。

分别配置 Qt5 和 Qt6：

```bash
qt5ct
qt6ct
```

在两个程序的颜色方案中选择 Noctalia 生成的方案。Noctalia 生成的文件通常位于：

```text
~/.config/qt5ct/colors/noctalia.conf
~/.config/qt6ct/colors/noctalia.conf
```

## 会话环境

Qt6 是当前默认环境：

```bash
printf '%s\n' "$QT_QPA_PLATFORMTHEME"
```

预期输出：

```text
qt6ct
```

首次设置或修改后，完整注销并重新登录 Mango 会话。只重新打开终端不能保证由 Mango 启动的应用继承新的环境变量。

Qt5 和 Qt6 不能通过一个 `QT_QPA_PLATFORMTHEME` 值同时指定。需要强制 Qt5 应用使用 Qt5 主题时：

```bash
QT_QPA_PLATFORMTHEME=qt5ct application-name
```

Qt6 应用使用默认的 `qt6ct`。

## GTK 宿主依赖

Nix 提供 GTK 主题包，但 GTK 的设置同步仍依赖宿主系统的 GSettings、dconf 和用户 D-Bus。检查：

```bash
command -v gsettings
command -v dconf
gsettings list-schemas | grep org.gnome.desktop.interface
printf '%s\n' "$DBUS_SESSION_BUS_ADDRESS"
```

宿主缺少这些组件时，按发行版安装：

```bash
# Fedora
sudo dnf install glib2 dconf

# Arch
sudo pacman -S glib2 dconf

# Ubuntu / Debian
sudo apt install libglib2.0-bin dconf-gsettings-backend
```

Mango 应从正常的图形登录会话启动，不能在没有用户 D-Bus 的裸 TTY shell 中直接启动后期待 GTK 设置同步。

## 字体验证

字体由 `fonts.nix` 安装和配置。切换 Home Manager 后，在当前图形会话中检查：

```bash
fc-match sans-serif:lang=zh-cn
fc-match serif:lang=zh-cn
fc-match monospace:lang=zh-cn
fc-match emoji
fc-match 'Noto Sans SC'
```

预期至少能看到：

```text
Noto Sans CJK SC
Noto Serif CJK SC
Noto Sans Mono CJK SC
Noto Color Emoji
Noto Sans CJK SC
```

如果刚切换后应用仍缺字或 Emoji 为空框，先刷新当前用户字体缓存并重启应用：

```bash
fc-cache -f
```

微信等常驻托盘程序需要从托盘完全退出后再启动。XWayland 应用发虚属于显示器缩放问题，不是字体包问题，见 [显示器配置](displays.md)。

## 动态文件所有权

以下文件由 Noctalia、`nwg-look` 或 `qt5ct`/`qt6ct` 运行时修改，不要用 Home Manager 声明为静态 `xdg.configFile`：

```text
~/.config/gtk-3.0/gtk.css
~/.config/gtk-3.0/noctalia.css
~/.config/gtk-4.0/gtk.css
~/.config/gtk-4.0/noctalia.css
~/.config/qt5ct/colors/noctalia.conf
~/.config/qt6ct/colors/noctalia.conf
```

如果 Home Manager 报这些文件会被 clobber，先确认文件所有权，不要直接删除它们。
