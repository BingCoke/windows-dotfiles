$ErrorActionPreference = "Stop"

$weztermArgs = @("start", "--always-new-process", "--", "nvim", "--") + $args
$process = Start-Process -FilePath "wezterm-gui.exe" -ArgumentList $weztermArgs -Wait -PassThru
exit $process.ExitCode
