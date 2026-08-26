# Linux 用户软件环境

这套配置用 Nix 和 Home Manager 安装 Linux 用户软件。桌面配置文件和其他应用配置由外部配置工具提供；本目录只负责软件 profile 和 Home Manager 激活。

当前支持 `x86_64-linux`。桌面 profile 适用于已经有图形驱动和 Wayland 会话的 Linux 主机；纯 Shell profile 不安装任何 Wayland 或桌面软件。

## 快速开始

### 1. 安装 Nix

Ubuntu、Fedora、Arch 等使用 systemd 的 Linux 主机推荐 daemon 模式：

```bash
curl -L https://nixos.org/nix/install -o /tmp/install-nix
less /tmp/install-nix
sh /tmp/install-nix --daemon
rm /tmp/install-nix
```

关闭并重新打开终端，然后启用 flakes：

```bash
mkdir -p ~/.config/nix
printf '%s\n' 'experimental-features = nix-command flakes' > ~/.config/nix/nix.conf
nix --version
systemctl status nix-daemon.socket
```

如果当前 Shell 找不到刚安装的 `nix`，重新打开终端，不要在旧 Shell 中继续执行后续命令。

### 2. 选择 profile

先进入已经部署好的配置目录：

```bash
cd ~/.config/home-manager
nix eval --json '.#homeConfigurations' --apply builtins.attrNames
```

当前 profile：

| Profile | 类型 | 用户 |
| --- | --- | --- |
| `kryond@iv-ufs` | 桌面 | `kryond` |
| `bingcoke@home` | 桌面 | `bingcoke` |
| `kryond@iv-ufs-shell` | 纯 Shell | `kryond` |
| `bingcoke@home-shell` | 纯 Shell | `bingcoke` |

profile 名称不是自动探测结果。它决定 Home Manager 使用的用户名和 home 目录；新用户或新目录需要先增加对应的 `hosts/*.nix` 和 flake 输出，详见 [profile 说明](docs/profiles.md)。

### 3. 首次构建和应用

先只构建，确认配置可以求值并下载依赖。桌面 profile 因为使用宿主 GPU 的 `nixGL`，必须使用 `--impure`：

```bash
PROFILE=bingcoke@home
nix run github:nix-community/home-manager -- \
  build --impure --flake ".#$PROFILE"
nix run github:nix-community/home-manager -- \
  switch --impure --flake ".#$PROFILE"
```

纯 Shell profile 不使用 GPU 探测：

```bash
PROFILE=bingcoke@home-shell
nix run github:nix-community/home-manager -- \
  build --flake ".#$PROFILE"
nix run github:nix-community/home-manager -- \
  switch --flake ".#$PROFILE"
```

`switch` 成功后，`home-manager` 通常已经在用户 profile 中可用。Rust 开发环境中的 `cargo` 和 `rustc` 由 Nix 提供，不依赖宿主系统预装 Rust。

Cargo 用户工具脚本是可选步骤：

```bash
~/.config/home-manager/scripts/install-tools.sh
```

该脚本安装到 `~/.cargo/bin`，不属于 Nix store；需要单独更新或删除时按 [开发工具说明](docs/development-tools.md) 处理。

### 4. 桌面主机的人工收尾

Nix 已经安装桌面软件，但以下两项依赖新主机的宿主系统或显示器硬件，需要手动执行：

```bash
noctalia-host-auth check
noctalia-host-auth install
noctalia-host-auth test
```

认证桥的宿主依赖和故障处理见 [Noctalia 宿主认证](docs/noctalia-host-auth.md)。新电脑的显示器型号、排列和缩放比例需要重新确认，见 [显示器配置](docs/displays.md)。GTK/Qt 主题首次配置和字体检查见 [Noctalia GTK/Qt 主题与字体](docs/noctalia-theme.md)。

纯 Shell 主机不需要执行这些桌面步骤。

## 日常操作

修改 Nix 文件后，先构建再应用：

```bash
PROFILE=bingcoke@home
home-manager build --impure --flake ".#$PROFILE"
home-manager switch --impure --flake ".#$PROFILE"
```

纯 Shell profile 去掉 `--impure`。完整的更新、锁文件、generation 和回滚规则见 [日常运维](docs/operations.md)。

查看软件和 generation：

```bash
home-manager packages
home-manager generations
```

## 所有权边界

- Nix/Home Manager：安装用户软件、Rust/Go 等开发工具，以及当前 profile 声明的生成文件。
- 宿主发行版：内核、GPU 驱动、设备节点、systemd、PAM、polkit 和其他 root 级系统组件。
- 外部配置管理：Mango、Noctalia、Neovim、终端、Shell 和 Git 配置文件。

同一个配置文件只能由一个工具管理。Home Manager 报 `Existing file would be clobbered` 时，不要直接删除文件，先根据 [profile 和冲突说明](docs/profiles.md) 确认它的归属。

## 文档

- [前置条件](docs/prerequisites.md)
- [Profile 和新主机](docs/profiles.md)
- [显示器配置](docs/displays.md)
- [Noctalia 宿主认证](docs/noctalia-host-auth.md)
- [Noctalia GTK/Qt 主题与字体](docs/noctalia-theme.md)
- [开发工具](docs/development-tools.md)
- [日常运维、更新和回滚](docs/operations.md)
