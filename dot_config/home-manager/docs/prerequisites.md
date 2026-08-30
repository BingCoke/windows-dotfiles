# 前置条件

## 支持范围

当前 flake 固定使用：

```text
x86_64-linux
```

支持使用 systemd 的 Fedora、Ubuntu/Debian、Arch 等 Linux 主机。当前不承诺 `aarch64-linux`、macOS 或 Windows。

纯 Shell profile 只需要 Nix daemon、当前用户的 home 目录和网络访问。桌面 profile 还需要宿主系统提供可工作的 GPU 驱动、Wayland 会话、用户 systemd 和 D-Bus。

## 安装 Nix

推荐 daemon 模式：

```bash
curl -L https://nixos.org/nix/install -o /tmp/install-nix
less /tmp/install-nix
sh /tmp/install-nix --daemon
rm /tmp/install-nix
```

安装后重新打开终端，确认 daemon：

```bash
nix --version
systemctl status nix-daemon.socket
```

启用 flakes：

```bash
mkdir -p ~/.config/nix
printf '%s\n' 'experimental-features = nix-command flakes' > ~/.config/nix/nix.conf
nix flake --help
```

不要在旧的、尚未加载 Nix 初始化脚本的 Shell 中继续执行安装命令。

## 宿主系统职责

Nix profile 不会安装或修改以下 root 级组件：

- Linux 内核、GPU 驱动和设备节点
- systemd、D-Bus、显示管理器和自动登录
- PAM、polkit、`pkexec`
- PipeWire 或其他发行版基础服务

Noctalia 的认证桥是唯一需要额外 root 操作的桌面收尾步骤，见 [Noctalia 宿主认证](noctalia-host-auth.md)。

## 非 NixOS GPU 集成

桌面 profile 使用 Home Manager 的 `targets.genericLinux.gpu` 集成。它把 Nix 构建的 GPU 库注册到宿主系统的 `/run/opengl-driver`，因此 Mango 和其他 Nix 图形程序不需要 `nixGL` 包装，也不会把 Nix 图形库路径传给宿主 GUI 应用。

首次切换桌面 profile 后，执行下面的命令安装 GPU 库：

```bash
sudo "$(command -v non-nixos-gpu-setup)"
```

该命令安装 `/etc/tmpfiles.d/non-nixos-gpu.conf`，让 `/run/opengl-driver` 在启动时自动创建。如果希望以后直接使用 `sudo non-nixos-gpu-setup`，可在切换后创建一次系统入口：

```bash
sudo ln -sfn "$(command -v non-nixos-gpu-setup)" /usr/local/bin/non-nixos-gpu-setup
```

纯 Shell profile 不导入桌面模块和 GPU 集成，可以使用纯 flake 命令：

```bash
home-manager switch --flake '.#bingcoke@home-shell'
```
