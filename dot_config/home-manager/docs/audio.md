# 用户级音频服务

桌面 profile 通过 `modules/audio.nix` 管理当前用户的音频栈：

- PipeWire 服务和原生 socket
- pipewire-pulse 服务和 PulseAudio 兼容 socket
- WirePlumber 会话管理器
- filter-chain 服务
- 音量工具 pavucontrol、pamixer 和媒体控制工具 playerctl

服务定义来自当前锁定的 Nix 包，PipeWire 的会话管理依赖指定为 `wireplumber.service`。这些定义安装到用户的 `~/.config/systemd/user/`，并声明默认启动和 socket 启动依赖。执行文件、服务端模块和 WirePlumber 来自同一份 nixpkgs；Noctalia 和桌面 portal 使用该 nixpkgs 的 PipeWire 客户端库。

## 作用范围

同一用户的 Niri、GNOME 和非图形会话共用同一个 systemd 用户管理器及音频 socket，因此都使用这套音频服务。服务随用户管理器启动或按 socket 激活，不跟随某个 compositor 的退出而停止。

未应用本配置的其他用户仍使用宿主音频服务。若需要保留完整的宿主 GNOME 环境，可使用其他用户登录 GNOME。本配置不创建用户，不卸载宿主软件包，也不修改 `/etc/systemd/user` 或 `/usr/lib/systemd/user`。

宿主仍负责内核音频驱动、设备权限、D-Bus、实时调度设施及蓝牙系统服务。宿主程序或 Flatpak 可以通过标准音频 socket 连接 Nix 服务；它们的客户端库不必因此改由 Nix 安装。

纯 Shell profile 不导入音频模块。

## 首次接管

先构建再应用当前桌面 profile，按 [日常运维](operations.md) 操作。应用成功后，首次从宿主服务切换时协调重启服务和 socket：

```bash
systemctl --user daemon-reload
systemctl --user stop \
  pipewire-pulse.service filter-chain.service wireplumber.service \
  pipewire.service pipewire-pulse.socket pipewire.socket
systemctl --user start \
  pipewire.service wireplumber.service pipewire-pulse.service filter-chain.service
```

这会短暂中断音频；已有应用可能需要重新连接。以后 Home Manager 更新服务定义时使用正常的用户 systemd 激活流程。

## 检查

```bash
systemctl --user show \
  pipewire.service pipewire-pulse.service wireplumber.service filter-chain.service \
  -p FragmentPath -p ExecStart -p MainPID -p ActiveState
systemctl --user status pipewire.socket pipewire-pulse.socket
wpctl status
wpctl get-volume @DEFAULT_AUDIO_SINK@
wpctl get-volume @DEFAULT_AUDIO_SOURCE@
```

四个服务的执行文件应指向 `/nix/store/`，PipeWire 服务端版本应与当前 profile 的 `pipewire --version` 一致。确认输出设备、麦克风、Noctalia 音量和静音控制，再实际播放和录音。

## 回滚

回滚 Home Manager generation 后，再执行上面的服务和 socket 停止／启动命令，确保运行中的进程使用回滚后的定义。

回滚到引入音频模块之前的 generation，会移除该 generation 不声明的用户级覆盖；宿主原有的服务定义和启用关系未被修改，因此本机原有服务可重新启动。没有宿主音频服务的新主机，应回滚到仍包含音频模块的可用 generation。
