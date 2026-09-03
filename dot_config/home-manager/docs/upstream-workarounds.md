# 上游问题与本地绕过跟踪

本页记录为了绕过上游或宿主环境问题而保留的源码补丁、源码版本固定和兼容配置。普通功能选择（例如 Fcitx5 addons、静态字体包和 `flake.lock`）不在此列。

处理这些项目时，不要只因为出现了新版本就删除本地修改。必须先确认修复已经进入所用的上游 release 和 nixpkgs 分支，再完成未应用绕过时的构建及运行验证。

## 通用检查流程

1. 查看本页中的上游状态和撤销条件。
2. 确认上游 release 包含目标修复，或已经提供可替代源码补丁的配置接口。
3. 确认 `nixos-unstable` 中的软件包已经包含该 release 或修复：

   ```bash
   nix eval --raw github:NixOS/nixpkgs/nixos-unstable#PACKAGE.version
   nix eval --raw github:NixOS/nixpkgs/nixos-unstable#PACKAGE.src.rev
   nix eval --json github:NixOS/nixpkgs/nixos-unstable#PACKAGE.patches \
     --apply 'map toString'
   ```

4. 在一个本地改动中移除绕过，但暂不执行 `switch`。
5. 构建受影响的 profile：

   ```bash
   home-manager build --flake '.#bingcoke@home'
   home-manager build --flake '.#kryond@iv-ufs'
   ```

6. 检查生成结果确实使用 nixpkgs 包，而不是旧的补丁或源码固定。
7. 执行 `switch`，重启相关进程并完成该项目列出的运行验证。
8. 如果验证失败，恢复绕过并更新本页状态；不能用“构建成功”代替运行验证。

当前 flake 跟踪 `nixos-unstable`。如果以后切换分支，上面的检查 URL 和撤销条件也必须改为实际使用的分支。

## xdg-desktop-portal-wlr 首帧后停止

| 项目 | 当前值 |
| --- | --- |
| 本地实现 | `modules/compositors.nix` 中固定上游源码；Mango 和 Niri 共用 |
| 固定提交 | [`c0255d7b047b7263629ab5a314661045ff7f65e3`](https://github.com/emersion/xdg-desktop-portal-wlr/commit/c0255d7b047b7263629ab5a314661045ff7f65e3) |
| 本地版本名 | `0.9.0-dev-c0255d7` |
| 当前正式 release | `v0.8.4`，不包含该提交 |
| 当前锁定 nixpkgs 包 | `0.8.4` |

### 原因

`v0.8.4` 的 wlr-screencopy 路径在完成并提交一帧后没有再次调用 `pw_stream_trigger_process()`。流作为 PipeWire driver 运行时只会交付进入 `STREAMING` 时预先触发的一帧，随后停止。节点仍显示 `running`，通常也不会产生 PipeWire 错误。

上游提交 `c0255d7` 在每次 wlr-screencopy capture cycle 完成后重新触发 graph。本机已通过运行时 A/B 验证：`0.8.4` 在 RustDesk 中首帧后冻结，包含该提交的构建可以持续捕获。

### 撤销条件

同时满足以下条件后，删除 `modules/compositors.nix` 中的 `overrideAttrs`，让 Mango 和 Niri 重新使用 `pkgs.xdg-desktop-portal-wlr`：

1. xdg-desktop-portal-wlr 发布的新 tag 包含 `c0255d7`；或者 nixpkgs 在当前 release 包上明确回移了等价修复。
2. 实际使用的 `nixos-unstable` 包包含该 release 或回移补丁。
3. 未固定源码的 Home Manager generation 中，Mango、Niri 和 Niri 的两个 systemd service 链接解析到同一个 nixpkgs derivation。
4. RustDesk 重启后可以连续更新画面，不再只显示首帧。

### 检查方法

检查上游最新 release：

```bash
curl -fsSL https://api.github.com/repos/emersion/xdg-desktop-portal-wlr/releases/latest \
  | jq -r '.tag_name, .html_url'
```

确认某个 release tag 包含修复提交：

```bash
git clone https://github.com/emersion/xdg-desktop-portal-wlr.git /tmp/xdpw-check
git -C /tmp/xdpw-check merge-base --is-ancestor \
  c0255d7b047b7263629ab5a314661045ff7f65e3 RELEASE_TAG
```

退出状态为 `0` 才表示该 tag 包含修复。随后检查 nixpkgs：

```bash
nix eval --raw github:NixOS/nixpkgs/nixos-unstable#xdg-desktop-portal-wlr.version
nix eval --raw github:NixOS/nixpkgs/nixos-unstable#xdg-desktop-portal-wlr.src.rev
nix eval --json github:NixOS/nixpkgs/nixos-unstable#xdg-desktop-portal-wlr.patches \
  --apply 'map toString'
```

撤销后的运行验证：

```bash
systemctl --user daemon-reload
systemctl --user restart xdg-desktop-portal-wlr.service xdg-desktop-portal.service
systemctl --user show xdg-desktop-portal-wlr.service \
  -p ExecStart -p FragmentPath -p ActiveState
```

然后重启 RustDesk，并在远端连接中持续移动窗口或播放动态内容至少 30 秒。

## xwayland-satellite DingTalk 窗口角色

| 项目 | 当前值 |
| --- | --- |
| 本地实现 | `patches/xwayland-satellite-dingtalk-popup.patch` |
| 应用位置 | `modules/niri.nix` 中的 `patchedXwaylandSatellite` |
| 当前锁定 nixpkgs 包 | `0.8.2` |
| 保护措施 | 包版本不是 `0.8.2` 时停止求值，要求人工复核补丁 |

### 原因

DingTalk 的部分 X11 子窗口提供的 window type、Motif hints 和尺寸 hints 不能被当前 xwayland-satellite 通用启发式正确转换为 Wayland popup。补丁按这些属性区分菜单、表情面板、主窗口和图片窗口。

这个补丁是应用兼容规则，不应以“上游增加 DingTalk 硬编码”为目标。当前 xwayland-satellite 没有允许用户按 `WM_CLASS`、`_NET_WM_WINDOW_TYPE`、Motif hints 或尺寸 hints 覆盖 `Popup`/`Toplevel` 的配置接口。

### 撤销或迁移条件

满足以下任一技术条件，并通过完整运行验证后处理：

1. **上游提供通用窗口角色配置接口。** 将当前规则迁移到配置层，再删除源码补丁和 `0.8.2` 版本断言。
2. **上游通用启发式解决了这类属性组合。** 未包含 DingTalk 应用名硬编码的上游版本可以自然正确识别这些窗口时，直接删除补丁和版本断言。

只出现新的 xwayland-satellite release 不足以撤销。版本断言触发时，应先将补丁试应用到新源码并检查上游的窗口角色代码和配置文档，再决定迁移、重写或删除。

### 检查方法

检查上游 release 和 nixpkgs 包：

```bash
curl -fsSL https://api.github.com/repos/Supreeeme/xwayland-satellite/releases/latest \
  | jq -r '.tag_name, .html_url'
nix eval --raw github:NixOS/nixpkgs/nixos-unstable#xwayland-satellite.version
nix eval --raw github:NixOS/nixpkgs/nixos-unstable#xwayland-satellite.src.rev
```

检查是否出现通用规则接口或相关启发式变化：

```bash
git clone https://github.com/Supreeeme/xwayland-satellite.git /tmp/xwayland-satellite-check
rg -n -i 'window.?rule|window.?role|wm_class|popup|heuristic' \
  /tmp/xwayland-satellite-check/{README.md,xwayland-satellite.man,src}
```

撤销或迁移后至少验证：

- DingTalk 菜单是 popup，不作为独立平铺窗口出现；
- 表情面板是 popup；
- 主窗口保持正常 toplevel；
- 图片查看窗口保持正常 toplevel；
- 窗口焦点、位置和关闭行为正常。

必要时使用 `xprop` 比较四类窗口的：

```text
WM_CLASS
_NET_WM_WINDOW_TYPE
WM_NORMAL_HINTS
_MOTIF_WM_HINTS
WM_TRANSIENT_FOR
```

## Noctalia 在非 NixOS 上的认证桥

| 项目 | 当前值 |
| --- | --- |
| 本地实现 | `scripts/noctalia-host-auth.sh` 和 `modules/compositors.nix` 中的包装命令 |
| 宿主文件 | `/etc/tmpfiles.d/noctalia-host-auth.conf`、`/run/wrappers/bin/*` |
| 上游跟踪 | [Home Manager #7027](https://github.com/nix-community/home-manager/issues/7027) |
| 当前状态 | issue 未关闭，尚无已确认 release 修复 |

### 原因

Nix 构建的 PAM/polkit 组件可能引用 NixOS 提供的 `/run/wrappers/bin/unix_chkpwd` 或 `polkit-agent-helper-1`，generic Linux 宿主不会自动创建这些路径。脚本只链接经过所有权、权限和宿主包归属检查的 helper，或使用宿主提供的 polkit socket。

### 撤销条件

不能只根据 Noctalia 版本判断。只有同时满足以下条件才能执行 `sudo noctalia-host-auth remove`：

1. 当前 Home Manager/nixpkgs/Noctalia 组合在 generic Linux 上不再依赖缺失的 NixOS wrapper 路径，或已经提供受支持的宿主集成方案。
2. 移除桥后锁屏密码认证和 polkit 授权都能使用宿主组件成功完成。
3. 重启后仍然有效，证明不是依赖遗留的 `/run` 文件。

### 检查方法

```bash
curl -fsSL https://api.github.com/repos/nix-community/home-manager/issues/7027 \
  | jq -r '.state, .html_url, .closed_at'
noctalia-host-auth check
noctalia-host-auth test
```

准备撤销时，先记录现状；移除后重启并重复锁屏和 polkit 测试。如果失败，重新执行 `noctalia-host-auth install`。

## 当前用户的 portal service 链接

| 项目 | 当前值 |
| --- | --- |
| 本地实现 | `modules/compositors.nix` 中两个 portal user unit 链接；`modules/niri.nix` 中一个 Niri wants 链接 |
| 作用 | 确保 Ubuntu 的 user systemd 优先找到当前用户的 Nix portal，并让 `niri.service` 显式启动 WLR portal |
| 影响范围 | 仅应用该 desktop profile 的用户；不修改 `/usr` 下的系统 unit，也不影响其他用户 |
| 上游跟踪 | 当前没有精确 issue；属于 generic Linux 会话发现与启动保证 |

Mango 和 Niri 共用 `~/.config/systemd/user` 下的 portal unit。Niri 额外使用自己的 wants 链接；Mango 通过 user D-Bus activation 启动同一个 WLR backend。两套桌面的 ScreenCast 和 Screenshot 都由各自的 portal 配置明确路由到 `wlr`。

### 撤销条件

只有 Ubuntu 的 user systemd 和 D-Bus 在不创建这些显式链接时，仍能从 Home Manager profile 稳定发现固定的 portal 包，才考虑删除链接。验证必须覆盖全新 Mango 和 Niri 登录，不能复用已经运行的 portal 进程。

### 检查方法

先确认当前链接没有写入系统目录：

```bash
readlink -f ~/.config/systemd/user/xdg-desktop-portal.service
readlink -f ~/.config/systemd/user/xdg-desktop-portal-wlr.service
systemd-analyze --user unit-paths
busctl --user list --activatable | grep org.freedesktop.impl.portal.desktop.wlr
```

在测试 generation 中移除显式链接并分别重新登录 Mango 和 Niri，然后检查：

```bash
systemctl --user show xdg-desktop-portal-wlr.service \
  -p ActiveState -p FragmentPath -p ExecStart
```

最后分别执行一次截图和 RustDesk 屏幕捕获。只有两个 compositor 的 fresh login、D-Bus activation 和实际 portal 请求都通过后，才删除通用 unit 链接；Niri wants 链接可以单独验证和撤销。

## 不属于待撤销绕过的配置

以下内容是当前系统的正常功能或所有权选择，不因上游发布新版本而自动删除：

- `modules/input-method.nix` 中选择 Fcitx5 addons；
- `modules/fonts.nix` 中选择静态 Noto CJK 字体包；
- `flake.lock` 对 nixpkgs 和 Home Manager 的正常版本锁定；
- `targets.genericLinux` 的 GPU 集成及其宿主初始化；
- GDM compositor session 文件安装工具；
- 外部配置管理与 Home Manager 之间的文件所有权边界。
