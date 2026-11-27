# Noctalia 宿主认证

Noctalia 由 Nix 安装。5.6.0 起，锁屏通过独立的 `noctalia-pam-helper` 认证；非 NixOS 主机需要用宿主编译器和 PAM 库构建它。polkit 授权继续使用现有的宿主认证桥。

这只适用于桌面 profile。纯 Shell profile 不安装 Noctalia。NixOS 应使用系统原生的 polkit/PAM 配置，不要执行本页的桥接脚本。

## 安装宿主组件

```bash
# Fedora
sudo dnf install polkit pam pam-devel gcc-c++
sudo dnf upgrade --refresh selinux-policy selinux-policy-targeted

# Arch
sudo pacman -S polkit pam gcc

# Ubuntu / Debian
sudo apt install polkitd pkexec libpam-modules-bin libpam0g-dev g++
```

## 构建锁屏 helper

Home Manager 构建并切换到新版本后，以桌面用户执行，不加 sudo：

```bash
noctalia-host-auth build-pam
```

命令使用 Home Manager 选中的 `pkgs.noctalia.src`，用宿主 PATH 中的 C++ 编译器编译上游 `pam_helper_main.cpp` 和协议头文件，按上游独立 helper 目标的依赖链接宿主 `libpam`，PAM service 为默认的 `login`。不需要构建整个 Noctalia，也不修改上游源码。该 service 使用宿主 `/etc/pam.d/login`。

helper 安装到 `~/.local/libexec/noctalia/<Noctalia版本>/noctalia-pam-helper`。Home Manager 设置 `NOCTALIA_PAM_HELPER_PATH` 指向对应版本。每台机器分别构建；不要通过 chezmoi 同步二进制，也不要将 Ubuntu 的产物复制到 Fedora。升级 Noctalia 后重新执行 `build-pam`。

重新登录 Niri，让 Noctalia 继承新的会话变量。只在终端中 export 不会改变已经运行的 Noctalia 的环境。可检查启动环境与链接库：

```bash
printf '%s\n' "$NOCTALIA_PAM_HELPER_PATH"
ldd "$NOCTALIA_PAM_HELPER_PATH"
```

`libpam.so.0` 必须解析到宿主库，不能是 `/nix/store` 中的 PAM。helper 使用上游权限模型，不创建新的 setuid 程序。

上游依据：[5.6.0 打包说明](https://github.com/noctalia-dev/noctalia/blob/v5.6.0/PACKAGING.md#runtime)、[锁屏 FAQ](https://docs.noctalia.dev/noctalia/v5.6.0/getting-started/faq/)。

## 配置和测试 polkit 桥

在已经运行 Noctalia 的图形会话中执行：

```bash
noctalia-host-auth check
noctalia-host-auth install
noctalia-host-auth test
```

`check` 分别报告当前版本的 PAM helper 是否存在，以及宿主桥是否就绪。这是安装检查，不能代替输入密码的运行验证。

`install` 会请求 sudo。沿用当前脚本：只链接经过所有权、权限和宿主包归属检查的认证 helper，或启用宿主提供的 polkit socket；不会复制宿主 helper。Fedora 现有脚本已由用户确认可用，保留其 socket/helper 选择、路径候选和 SELinux 检查。新的锁屏 helper 在 Fedora 上仍需实际验证。

`test` 只执行 `/usr/bin/true`，用于确认 polkit 认证弹窗可用，不会修改系统。测试要求 Noctalia 正在运行；它不测试锁屏密码。

每个图形会话只能运行一个 polkit agent。当前使用 Noctalia 的 agent 时，不要同时启动 LXQt、KDE 或 GNOME 的另一个 agent。`lxqt-policykit` 只是 profile 中提供的备用软件，不要和 Noctalia agent 同时自动启动。

## 锁屏验证和旧桥

确认 Noctalia 已运行新版本、继承了 `NOCTALIA_PAM_HELPER_PATH`，再测试锁屏和正确密码解锁，并在重启后重复锁屏与 polkit 测试。Ubuntu 和 Fedora 分别验证。

现有 `install` 仍保留 `/run/wrappers/bin/unix_chkpwd` 桥及 tmpfiles 声明，便于当前旧进程和回滚使用。新锁屏 helper 通过宿主 PAM 认证，不依赖这条 NixOS 路径。只有两台机器分别完成验证后，再处理旧桥清理和相应安装逻辑；不要只手删链接，也不要执行 `remove` 来单独撤掉它，`remove` 会同时删除 polkit 桥。

## 失败时检查

先执行：

```bash
noctalia-host-auth check
```

如果锁屏 helper 缺失，安装本页的宿主编译依赖，再执行 `noctalia-host-auth build-pam`。如果 helper 已存在但密码仍失败，核对 Noctalia 进程的启动环境、`ldd` 结果和宿主 `/etc/pam.d/login`。

如果显示宿主桥未就绪，使用当前发行版的包管理器安装本页依赖，再执行 `noctalia-host-auth install`。如果 Fedora 的 polkit 测试提示 SELinux 阻止认证，先更新 SELinux policy，再重新测试：

```bash
sudo dnf upgrade --refresh selinux-policy selinux-policy-targeted
noctalia-host-auth test
```

如果提示 Noctalia 没有运行，先进入 Niri 会话并确认 Noctalia 已启动。不要通过关闭认证检查、关闭 SELinux 或手动复制 `/usr` 下的 helper 绕过问题。

## 撤销

需要完整撤销桥接时执行：

```bash
noctalia-host-auth remove
```

该命令通过包装器请求 sudo，只删除脚本管理的桥接文件；宿主 polkit socket 不会被删除，也不删除用户目录下的锁屏 helper。只有确认不再需要桥或已切换到其他认证集成后，才执行撤销。

回滚 Home Manager generation 会恢复对应版本的 helper 路径，但不会重新编译 helper，也不会撤销宿主桥。因此保留仍用于回滚的版本目录。
