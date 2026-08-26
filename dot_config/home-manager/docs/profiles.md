# Profile 和新主机

## 当前 profile

| Profile | 用户 | Home 目录 | 类型 |
| --- | --- | --- | --- |
| `kryond@iv-ufs` | `kryond` | `/home/kryond` | 桌面 |
| `bingcoke@home` | `bingcoke` | `/home/bingcoke` | 桌面 |
| `kryond@iv-ufs-shell` | `kryond` | `/home/kryond` | 纯 Shell |
| `bingcoke@home-shell` | `bingcoke` | `/home/bingcoke` | 纯 Shell |

profile 名称是 flake 中显式声明的属性，不会根据当前 hostname 自动选择。一次 Home 目录只应该选择一个 profile，不要把 desktop 和 shell 两个 profile 交替应用到同一个 home。

列出实际输出：

```bash
nix eval --json '.#homeConfigurations' --apply builtins.attrNames
```

## 桌面和纯 Shell 的区别

桌面 profile 在共享开发环境之外，还导入 Mango、Noctalia、Wayland 工具、显示器工具、输入法和字体配置。它需要宿主图形驱动，并使用 `--impure` 构建。

纯 Shell profile 只导入共享开发环境，包括：

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

它不安装 Mango、Noctalia、nixGL、Wayland、Fcitx5、字体或其他桌面软件。

## 新用户或新主机

如果新机器的用户名或 home 目录不同，不能直接使用现有的 `bingcoke` 或 `kryond` profile。增加一个主机文件，例如：

```nix
{ ... }:

{
  home.username = "alice";
  home.homeDirectory = "/home/alice";
}
```

保存为 `hosts/alice-laptop.nix` 后，在 `flake.nix` 增加对应的 desktop 或 shell 输出。输出名称和主机文件中的用户名、home 目录必须保持一致。

完成后先检查输出是否存在：

```bash
nix flake show
nix eval --json '.#homeConfigurations' --apply builtins.attrNames
```

再使用新输出执行 `build`，确认没有求值错误后再 `switch`。

## 文件冲突

Home Manager 只应管理 Nix 模块声明的文件。Mango、Neovim、终端、Shell 和 Git 配置由外部配置管理工具提供，不要同时在 Home Manager 中声明同一文件。

出现：

```text
Existing file ... would be clobbered
```

先确认文件归属，再处理冲突。不要用 `rm` 强行删除，也不要同时应用两个写入同一个 home 的 Home Manager profile。
