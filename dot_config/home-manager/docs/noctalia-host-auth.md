# Noctalia 宿主认证

Noctalia 由 Nix 安装，但密码认证使用宿主发行版的 PAM 和 polkit。非 NixOS 主机通常需要安装宿主认证组件，并建立一次认证桥。

这只适用于桌面 profile。纯 Shell profile 不安装 Noctalia，也不需要执行这些命令。

## 安装宿主组件

```bash
# Fedora
sudo dnf install polkit pam
sudo dnf upgrade --refresh selinux-policy selinux-policy-targeted

# Arch
sudo pacman -S polkit pam

# Ubuntu / Debian
sudo apt install polkitd pkexec libpam-modules-bin
```

NixOS 应使用系统原生的 polkit/PAM 配置，不要执行本页的桥接脚本。

## 配置和测试

Home Manager 成功切换后，在已经运行 Noctalia 的图形会话中执行：

```bash
noctalia-host-auth check
noctalia-host-auth install
noctalia-host-auth test
```

`install` 会请求 sudo。脚本只链接宿主已经安装并验证过的认证 helper，或启用宿主提供的 polkit socket；不会复制 helper，也不会创建新的 setuid 程序。

`test` 只执行 `/usr/bin/true`，用于确认认证弹窗可用，不会修改系统。测试要求 Noctalia 正在运行。

每个图形会话只能运行一个 polkit agent。当前使用 Noctalia 的 agent 时，不要同时启动 LXQt、KDE 或 GNOME 的另一个 agent。`lxqt-policykit` 只是 profile 中提供的备用软件，不要和 Noctalia agent 同时自动启动。

## 失败时检查

先重新执行：

```bash
noctalia-host-auth check
```

如果显示宿主组件缺失，使用当前发行版的包管理器安装本页的依赖。如果 Fedora 的测试提示 SELinux 阻止认证，先更新 SELinux policy，再重新测试：

```bash
sudo dnf upgrade --refresh selinux-policy selinux-policy-targeted
noctalia-host-auth test
```

如果提示 Noctalia 没有运行，先进入 Mango 会话并确认 Noctalia 已启动。不要通过关闭认证检查或手动复制 `/usr` 下的 helper 绕过问题。

## 撤销

只删除由脚本创建的桥接文件：

```bash
sudo noctalia-host-auth remove
```

宿主的 polkit socket 不会被删除。只有确认当前 Noctalia 版本不再需要这层桥时，才执行撤销。
