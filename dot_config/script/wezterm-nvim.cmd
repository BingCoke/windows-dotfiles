@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0wezterm-nvim.ps1" %*
exit /b %ERRORLEVEL%
