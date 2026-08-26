# 开发工具

共享基础环境由 Nix 安装：

```text
git
neovim
cargo
rustc
go
fnm
uv
lazygit
```

因此纯 Shell profile 不依赖宿主系统预装 Rust 或 Go。确认命令来源：

```bash
type -a cargo
type -a rustc
type -a go
type -a nvim
```

## Cargo 用户工具

`cargo install` 写入 `~/.cargo/bin`，不写入 Nix store。当前仓库提供的可选脚本会安装或检查：

```text
cargo-binstall
cargo-update
yazi / ya
zellij
ripgrep / rg
fd-find / fd
```

执行：

```bash
~/.config/home-manager/scripts/install-tools.sh
```

脚本优先使用预编译包，失败时使用 `cargo install --locked`。这些工具的版本不由 `flake.lock` 锁定；如果需要严格复现，应改为把具体工具加入 Nix module，而不是依赖脚本。

## PATH 冲突

同名命令可能同时存在于 Nix、Cargo 和 Go 用户目录。Shell 按 `PATH` 顺序选择，先确认来源再处理：

```bash
type -a rg
type -a fd
type -a yazi
type -a go
```

不要为了覆盖一个同名命令，直接删除另一个包或修改系统目录。应在对应的包管理层更新或移除它。
