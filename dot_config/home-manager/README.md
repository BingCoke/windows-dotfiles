# Linux 用户环境

这套配置使用 Nix 和 Home Manager 管理 Linux 用户软件，后续由 Chezmoi 统一管理配置源码以及其他软件的配置文件。

## 职责划分

- **Nix/Home Manager**：只负责安装 Linux 用户软件和管理用户 Nix profile。
- **Chezmoi**：管理 `~/.config/home-manager`、Git、Neovim、WezTerm、Fish、Bash 等配置文件。
- **Cargo/Go**：管理通过 `cargo install` 和 `go install` 安装的用户工具。
- **APT/DNF**：继续管理内核、驱动、systemd 等发行版基础组件。

同一个配置文件只能交给一个工具管理。例如 Git 由 Nix 安装，但 `~/.gitconfig` 或 `~/.config/git/config` 应交给 Chezmoi，不能同时交给 Home Manager。

## 目录结构

```text
.
├── flake.nix
├── flake.lock
├── home.nix
├── hosts/
│   ├── iv-ufs.nix
│   └── home.nix
├── modules/
│   ├── development.nix
│   ├── mango.nix
│   └── neovim.nix
└── scripts/
    └── install-tools.sh
```

- `flake.nix`：定义外部输入和 Home Manager 输出。
- `flake.lock`：锁定 nixpkgs、Home Manager、Mangobar 和 nixGL 的具体版本。
- `home.nix`：所有 Linux 机器共享的配置入口。
- `hosts/`：用户名、Home 目录等主机专属信息。
- `modules/`：按用途组织的软件包。
- `scripts/install-tools.sh`：Cargo 安装完成后手动执行一次的工具初始化脚本。

## 安装 Nix

Ubuntu、Fedora 等使用 systemd 的 Linux 推荐安装 daemon 模式。daemon 负责安全地管理共享的 `/nix/store`，Home Manager 仍然只配置当前用户。

先下载安装脚本并检查：

```bash
curl -L https://nixos.org/nix/install -o /tmp/install-nix
less /tmp/install-nix
```

执行安装：

```bash
sh /tmp/install-nix --daemon
rm /tmp/install-nix
```

Fish 不支持 Bash 的 `<(...)` 进程替换，因此不要直接在 Fish 中运行：

```bash
bash <(curl -L https://nixos.org/nix/install) --daemon
```

安装完成后关闭并重新打开终端，然后检查：

```bash
nix --version
systemctl status nix-daemon.socket
```

启用 `nix-command` 和 flakes：

```bash
mkdir -p ~/.config/nix
printf '%s\n' 'experimental-features = nix-command flakes' \
  > ~/.config/nix/nix.conf
```

检查：

```bash
nix flake --help
```

## Home Manager 配置名称

当前 flake 提供两套配置：

```text
kryond@iv-ufs   Ubuntu 工作机，用户 kryond
bingcoke@home   家用 Linux 机器，用户 bingcoke
```

名称来自 `flake.nix`：

```nix
homeConfigurations = {
  "kryond@iv-ufs" = mkHome ./hosts/iv-ufs.nix;
  "bingcoke@home" = mkHome ./hosts/home.nix;
};
```

可以查询实际输出名称：

```bash
nix eval --json '.#homeConfigurations' --apply builtins.attrNames
```

## 首次构建

进入配置目录：

```bash
cd ~/.config/home-manager
```

工作机先只构建，不应用：

```bash
nix run github:nix-community/home-manager -- \
  build --flake '.#kryond@iv-ufs'
```

`build` 成功表示配置可以求值，依赖可以下载或构建。它不会切换当前用户环境。

确认构建成功后应用：

```bash
nix run github:nix-community/home-manager -- \
  switch --flake '.#kryond@iv-ufs'
```

`switch` 会执行构建并激活新的用户 generation。首次成功后，配置会提供 `home-manager` 命令。

家用 Linux 机器使用：

```bash
home-manager switch --flake '.#bingcoke@home'
```

## 日常使用

修改 Nix 配置后，可先检查：

```bash
home-manager build --flake '.#kryond@iv-ufs'
```

确认后应用：

```bash
home-manager switch --flake '.#kryond@iv-ufs'
```

配置稳定后可以直接执行 `switch`，因为 `switch` 本身包含构建过程。

查看当前安装的软件：

```bash
home-manager packages
```

查看 generation：

```bash
home-manager generations
```

回滚到上一代：

```bash
home-manager switch --rollback
```

查看 Home Manager 更新说明：

```bash
home-manager news
```

## 更新依赖

`flake.lock` 应提交到配置仓库。日常 `switch` 使用锁定版本，不会自动追踪远端最新提交。

更新全部输入：

```bash
cd ~/.config/home-manager
nix flake update
home-manager build --flake '.#kryond@iv-ufs'
home-manager switch --flake '.#kryond@iv-ufs'
```

只更新某个输入，例如 nixGL：

```bash
nix flake update nixgl
```

更新前后都应保留 `flake.lock`，以便另一台机器复现相同环境。

## 添加软件

通用开发软件放在 `modules/development.nix`：

```nix
home.packages = with pkgs; [
  go
  fnm
  uv
  lazygit
];
```

Neovim 软件本体放在 `modules/neovim.nix`。Neovim 配置文件不放进 Home Manager，后续由 Chezmoi 管理。

MangoWM、Mangobar、Rofi、WezTerm 和测试用 nixGLIntel 放在 `modules/mango.nix`。

添加包后运行：

```bash
home-manager switch --flake '.#kryond@iv-ufs'
```

查询包名：

```bash
nix search nixpkgs <关键词>
```

## Cargo 和 Go 用户工具

`~/.cargo/bin` 和 `~/go/bin` 不由 Nix store 管理。通过 Cargo 或 Go 安装的工具可以与 Nix 软件共存；如果存在同名命令，Shell 按 `PATH` 顺序选择。

Cargo 安装完成后，手动运行一次：

```bash
~/.config/home-manager/scripts/install-tools.sh
```

当前脚本安装或检查：

```text
cargo-binstall
cargo-update
yazi / ya
zellij
ripgrep / rg
fd-find / fd
```

脚本优先使用 `cargo binstall` 的预编译包，没有可用预编译包时回退到 `cargo install --locked`。以后需要的 `go install` 命令也可以继续加入同一个脚本。

## MangoWM 测试

正常的 Mango 命令没有被 nixGL 包装：

```bash
mango
```

`nixGLIntel` 只用于旧 Linux、非 NixOS 图形库兼容问题或 Mango 升级后的对比测试。

先检查版本和配置：

```bash
mango -v
mango -c ~/.config/mango/config.conf -p
```

在现有 Wayland 会话中嵌套测试：

```bash
env WLR_BACKENDS=wayland \
  nixGLIntel mango -d -s wezterm \
  2>&1 | tee ~/mango-nixgl-test.log
```

回到启动终端按 `Ctrl+C` 退出。如果直接运行 `mango` 出现 EGL、GBM 或 renderer 错误，而 `nixGLIntel mango` 正常，通常说明问题位于 Nix 图形库与宿主 Mesa/驱动的衔接层。

Mango 配置位于：

```text
~/.config/mango/config.conf
```

它不由 Home Manager管理，后续应加入 Chezmoi。

## Chezmoi 集成计划

Chezmoi 默认源码目录：

```text
~/.local/share/chezmoi
```

未来由 Chezmoi 管理：

```text
~/.config/home-manager
~/.config/mango
~/.config/nvim
~/.config/wezterm
~/.config/fish
~/.gitconfig 或 ~/.config/git/config
```

Home Manager 只在 Linux 上部署。Chezmoi 的 `.chezmoiignore` 可以加入：

```gotemplate
{{ if ne .chezmoi.os "linux" }}
.config/home-manager/**
{{ end }}
```

建议保持两个显式步骤：

```bash
chezmoi apply
home-manager switch --flake ~/.config/home-manager#kryond@iv-ufs
```

暂时不要让 `chezmoi apply` 自动执行 `home-manager switch`。分开执行更容易定位模板错误、Nix 构建错误和 Home Manager 激活错误。

## 常见问题

### `Nix won't work in active shell sessions`

安装器修改了新 Shell 的初始化环境，当前已经运行的 Shell 不会自动更新。关闭并重新打开终端即可。

### `Existing file would be clobbered`

Home Manager 检测到目标文件已经存在并拒绝覆盖。不要直接删除文件，先确认该文件应该归 Chezmoi 还是 Home Manager 管理。

### 用户 systemd 显示 degraded

Home Manager 在 `switch` 末尾会检查整个用户 systemd 会话，并可能显示与当前 Nix 配置无关的历史失败单元。使用以下命令检查：

```bash
systemctl --user --failed
```

只清除历史失败状态：

```bash
systemctl --user reset-failed
```

这不会卸载、禁用或删除服务。

### 检查命令来自哪里

```bash
type -a nvim
type -a go
type -a mango
type -a rg
```

Nix/Home Manager 软件通常来自 `~/.nix-profile/bin`，Cargo 软件通常来自 `~/.cargo/bin`，Go 用户工具通常来自 `~/go/bin`。
