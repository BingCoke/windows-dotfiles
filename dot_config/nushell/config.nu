# config.nu
# Installed by:
# version = "0.112.2"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings,
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R
# #
source local.nu

$env.config.buffer_editor = 'nvim'

$env.EDITOR = "nvim"
$env.VISUAL = "nvim"

$env.config = ($env.config | upsert shell_integration {
  osc2: true
  osc7: true
  osc8: true
  osc9_9: false   # 改成 false
  osc133: false
  osc633: false
})

$env.config.history = {
  file_format: sqlite
  max_size: 1_000_000
  sync_on_enter: true
  isolation: true
}


def --env y [...args] {
	let tmp = (mktemp -t "yazi-cwd.XXXXXX")
	^yazi ...$args --cwd-file $tmp
	let cwd = (open $tmp)
	if $cwd != $env.PWD and ($cwd | path exists) {
		cd $cwd
	}
	rm -fp $tmp
}


# 启用外部命令路径解析高亮
$env.config.highlight_resolved_externals = true



# --- starship ---
# mkdir ($nu.data-dir | path join "vendor/autoload")
# starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
# --- zoxide ---
# zoxide init nushell | save -f ~/.zoxide.nu 
# source ~/.zoxide.nu


# --- keybindings ---
const ctrl_r = {
  name: history_menu
  modifier: CONTROL
  keycode: Char_r
  mode: [emacs, vi_insert, vi_normal]
  event: [
    {
      send: executehostcommand
      cmd: "
        let result = history
          | get command
          | reverse
          | uniq
          | each { |cmd| $cmd | str replace --all (char newline) ' ' }
          | str join (char nl)
          | fzf;
        commandline edit --append $result;
        commandline set-cursor --end
      "
    }
  ]
}

$env.config.keybindings ++= [{
  name: change_dir_with_fzf
  modifier: CONTROL
  keycode: Char_y
  mode: emacs
  event: {
    send: executehostcommand,
    cmd: "let result = fd --type d --hidden --exclude .git | str join (char nl) | fzf | decode utf-8 | str trim; commandline edit --insert $result"
  }
}]

$env.config.keybindings ++= [$ctrl_r]
