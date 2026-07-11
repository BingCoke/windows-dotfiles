@echo off
setlocal EnableDelayedExpansion

rem Create ESC character (ASCII 27)
for /f %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"

if "%~1"=="debug" (
  if not "%NVIM%"=="" (
    <nul set /p "=!ESC!]777;pi-nvim-debug!ESC!\"
    exit /b 0
  )

  echo nvim shim debug 1>&2
  echo NVIM: %NVIM% 1>&2
  echo script_dir: %~dp0 1>&2
  echo mode: normal terminal; this shim is only injected into managed Neovim terminals 1>&2
  exit /b 0
)

if "%NVIM%"=="" (
  echo nvim shim is only for managed Neovim terminals; use your system nvim externally 1>&2
  exit /b 127
)

set "sent="

:emit_targets
if "%~1"=="" goto done
set "arg=%~1"
if "%arg:~0,1%"=="-" (
  shift
  goto emit_targets
)
set "sent=1"
rem Convert to absolute path
for %%I in ("%~1") do set "path=%%~fI"
<nul set /p "=!ESC!]777;pi-nvim;!path!!ESC!\"
shift
goto emit_targets

:done
if not "%sent%"=="" exit /b 0
echo Usage: nvim ^<file^> [file ...] 1>&2
exit /b 2
