# 日常运维

## 修改后切换

先确认当前 profile，再构建：

```bash
PROFILE=bingcoke@home
nix flake check
home-manager build --impure --flake ".#$PROFILE"
home-manager switch --impure --flake ".#$PROFILE"
```

纯 Shell profile 不需要 `--impure`。构建失败时不要继续执行 `switch`，先根据错误定位到 flake、模块、包或宿主依赖。

## 更新输入

`flake.lock` 锁定 nixpkgs、Home Manager 和 nixGL 的版本。普通 `switch` 不会自动更新远端版本。

更新前先保留当前可用状态，然后执行：

```bash
nix flake update
home-manager build --impure --flake '.#bingcoke@home'
home-manager switch --impure --flake '.#bingcoke@home'
```

只更新某个输入：

```bash
nix flake update nixpkgs
```

如果更新后的构建或运行结果不符合预期，Home Manager generation 回滚只恢复已激活的用户环境，不会自动恢复 `flake.lock`。需要同时把 `flake.lock` 恢复到更新前版本，再重新构建。

## Generation 和回滚

查看已有 generation：

```bash
home-manager generations
```

回滚到上一代：

```bash
home-manager switch --rollback
```

查看 Home Manager 的版本提示：

```bash
home-manager news
```

回滚只影响 Home Manager 用户环境。它不会撤销宿主系统通过 `noctalia-host-auth install` 建立的认证桥，也不会恢复宿主 GPU、PAM 或 systemd 配置。

## 常见检查

检查当前 profile 安装的软件：

```bash
home-manager packages
type -a nvim
type -a cargo
type -a mango
```

如果新安装的 Nix 命令在当前终端不可见，关闭并重新打开终端。

如果 Home Manager 报目标文件已经存在，先查看 [Profile 和新主机](profiles.md) 的所有权说明，不要直接删除文件。

如果切换最后提示用户 systemd degraded：

```bash
systemctl --user --failed
```

确认失败单元与本次配置无关后，可以只清除历史失败状态：

```bash
systemctl --user reset-failed
```
