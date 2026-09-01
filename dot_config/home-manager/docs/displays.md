# 新电脑的显示器配置

显示器的品牌、型号、连接器名称、排列和缩放比例都依赖硬件。Nix 只安装 `wlr-randr`、`kanshi` 和相关工具，以下值需要在新电脑上重新确认。

## 识别输出

进入 Mango/Wayland 会话后执行：

```bash
wlr-randr --json | jq
```

确认每个输出的 `make`、`model` 和当前连接状态。也可以使用：

```bash
wdisplays
```

不要直接把旧电脑中的输出名复制到新电脑。笔记本内置屏幕、USB-C 扩展坞和显示器的名称可能完全不同。

## 写入 kanshi profile

编辑现有配置：

```text
~/.config/kanshi/config
```

根据新电脑的输出名称修改，例如：

```ini
profile default {
    output "AOC U27G4 *" enable scale 1.25
}
```

`AOC U27G4 *` 只是示例，必须替换为 `wlr-randr` 返回的实际品牌和型号。多屏时，为每个输出增加对应的 `output` 行，并按实际需要设置启用状态、位置和缩放。

重新加载并确认：

```bash
kanshictl reload
kanshictl status
wlr-randr
```

现有 Mango 启动配置如果已经执行 `kanshi`，不需要另行启动第二个 kanshi 进程。确认当前进程：

```bash
pgrep -a kanshi
```

## 1.25 和 1.5 缩放

Wayland 原生窗口使用 kanshi 的 `scale`。常用值：

```text
1.25
1.5
```

如果使用 XWayland 应用并保持当前 Mango 的 `xwayland_ignore_scale=1`，需要让 X11 应用通过 Xft DPI 自己放大：

```text
scale 1.25 -> Xft.dpi: 120
scale 1.5  -> Xft.dpi: 144
```

当前 Xft DPI 启动值位于：

```text
~/.config/mango/exec.conf
```

只在新屏幕缩放比例变化时修改该值。修改后重启受影响的 XWayland 应用；只重载 Mango 通常不会更新已经运行的应用。

## Noctalia 外接屏亮度

笔记本内置屏通常通过 `/sys/class/backlight` 和 `brightnessctl` 调节；HDMI/DP 外接屏通常通过 DDC/CI、`ddcutil` 和 `/dev/i2c-*` 调节。桌面 profile 已安装 `ddcutil`，但 Home Manager 不能配置非 NixOS 宿主的设备权限；如果 `/dev/i2c-*` 是 `root:root 0600`，Noctalia 会检测不到显示器。

先在显示器实体菜单中开启 DDC/CI，再按宿主系统安装权限规则：

```bash
# Ubuntu / Debian
sudo apt install ddcutil

# Fedora
sudo dnf install ddcutil i2c-tools

# Arch
sudo pacman -S ddcutil i2c-tools

# 安装后重新加载设备规则
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=i2c-dev
```

注销并重新登录，让 logind 重新授予当前桌面会话设备权限。NixOS 在系统配置中声明：

```nix
hardware.i2c.enable = true;
users.users.kryond.extraGroups = [ "i2c" ];
```

应用系统配置并重新登录后验证：

```bash
ls -l /dev/i2c-*
ddcutil detect
ddcutil getvcp 10
```

Noctalia 还需要 `[brightness] enable_ddcutil = true`。如果权限正常但 `ddcutil detect` 仍无显示器，检查显示器是否支持并已开启 DDC/CI，以及连接线或扩展坞是否透传 DDC；不要用 `chmod 666 /dev/i2c-*` 临时放开所有 I²C 设备。

## 故障判断

屏幕没有出现时，依次检查：

```bash
wlr-randr
kanshictl status
pgrep -a kanshi
```

- `wlr-randr` 看不到输出：先检查宿主驱动、连接线、扩展坞和 Wayland 会话。
- 能看到输出但 kanshi 没有应用 profile：检查 `~/.config/kanshi/config` 中的品牌型号是否匹配。
- Wayland 窗口清晰但 XWayland 窗口发虚：检查 `xwayland_ignore_scale` 和 Xft DPI 是否与新的 `scale` 对应。
- 屏幕排列错误：调整 kanshi 中的输出顺序和位置，不要通过重复启动 kanshi 解决。
