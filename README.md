# Dotfiles

这个仓库使用 [chezmoi](https://www.chezmoi.io/) 管理个人配置。部分终端和编辑器配置会读取环境变量来决定默认 shell。

## Shell 选择

使用 `DOTFILES_USE_SHELL` 指定想要让这些配置采用的 shell：

```powershell
$env:DOTFILES_USE_SHELL = 'nu'
    chezmoi apply
```

当前会读取这个变量的配置：

- WezTerm: 如果 `DOTFILES_USE_SHELL` 非空且能在 `PATH` 中找到，就设置为 `default_prog`。
- Zellij: 如果 `DOTFILES_USE_SHELL` 非空且能在 `PATH` 中找到，就写入 `default_shell`。
- Alacritty: 如果 `DOTFILES_USE_SHELL` 非空且能在 `PATH` 中找到，就写入 `terminal.shell.program`。
- Neovim: 仅在 Windows 上、`DOTFILES_USE_SHELL=nu` 且 `nu` 可执行时，启用 Nushell 专用的 `shell`、`shellcmdflag`、重定向和管道配置。

也就是说，如果 Windows 下想让这些配置使用 Nushell，需要先确保 `nu` 在 `PATH` 里，然后把变量设为 `nu`：

```powershell
$env:DOTFILES_USE_SHELL = 'nu'
chezmoi apply
```

上面的写法只对当前 PowerShell 会话和它启动的子进程生效。关闭终端后变量就不会保留。

## Windows 持久设置环境变量

推荐用 PowerShell 设置用户级环境变量：

```powershell
[Environment]::SetEnvironmentVariable('DOTFILES_USE_SHELL', 'nu', 'User')
```

设置后重新打开终端，让新进程继承这个变量，然后应用 chezmoi：

```powershell
chezmoi apply
```

如果希望当前这个 PowerShell 窗口立刻也能使用它，可以同时设置当前进程变量：

```powershell
$env:DOTFILES_USE_SHELL = 'nu'
```

恢复为默认 shell 时，删除用户级变量并重新打开终端：

```powershell
[Environment]::SetEnvironmentVariable('DOTFILES_USE_SHELL', '', 'User')
```

也可以通过 Windows 图形界面修改：

1. 打开“系统属性”。
2. 进入“高级”标签页。
3. 点击“环境变量”。
4. 在“用户变量”里新增或编辑 `DOTFILES_USE_SHELL`，值设为 `nu`。
5. 重新打开终端后运行 `chezmoi apply`。

CMD 里也可以用 `setx` 持久设置用户变量，但它同样只影响之后启动的新终端：

```cmd
setx DOTFILES_USE_SHELL nu
```

## 参考

- chezmoi 模板会处理 `.tmpl` 文件，并可通过 `env` 函数读取运行时环境变量：https://chezmoi.io/user-guide/templating/
- PowerShell 环境变量分为 Process、User、Machine 作用域；用户级和机器级变量需要用 `System.Environment` 或系统设置持久保存：https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables
