if ($Env:OS -ne "Windows_NT") { exit 0 }

$ErrorActionPreference = "Stop"
$hcu = [Microsoft.Win32.Registry]::CurrentUser

$menuKeys = @(
  'Software\Classes\Directory\shell\WezTermHere',
  'Software\Classes\Directory\Background\shell\WezTermHere',
  'Software\Classes\Directory\shell\NvimHere',
  'Software\Classes\Directory\Background\shell\NvimHere',
  'Software\Classes\*\shell\NvimHere'
)

function Remove-KeyTree([string]$SubKey) {
  $key = $hcu.OpenSubKey($SubKey)
  if ($key) {
    $key.Close()
    $hcu.DeleteSubKeyTree($SubKey, $false)
  }
}

function Remove-OwnedExtAssociations {
  $names = @()
  $classes = $hcu.OpenSubKey('Software\Classes')
  if ($classes) {
    $names += $classes.GetSubKeyNames()
    $classes.Close()
  }

  $fileExtsPath = 'Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts'
  $fileExts = $hcu.OpenSubKey($fileExtsPath)
  if ($fileExts) {
    $names += $fileExts.GetSubKeyNames()
    $fileExts.Close()
  }

  foreach ($name in ($names | Sort-Object -Unique)) {
    if (-not $name.StartsWith('.')) { continue }

    $extension = $hcu.OpenSubKey("Software\Classes\$name", $true)
    if ($extension) {
      if ($extension.GetValue('') -eq 'WezTerm.Nvim') {
        $extension.DeleteValue('', $false)
      }
      $extension.Close()
    }

    $openWith = $hcu.OpenSubKey("$fileExtsPath\$name\OpenWithProgids", $true)
    if ($openWith) {
      $openWith.DeleteValue('WezTerm.Nvim', $false)
      $openWith.Close()
    }
  }
}

foreach ($key in $menuKeys) { Remove-KeyTree $key }
Remove-OwnedExtAssociations
Remove-KeyTree 'Software\Classes\WezTerm.Nvim'

Write-Host 'Removed Windows context menus and WezTerm.Nvim file associations.'
