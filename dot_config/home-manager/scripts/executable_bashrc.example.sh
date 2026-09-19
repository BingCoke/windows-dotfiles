#!/usr/bin/env bash

# Optional Bash integrations for tools installed by Home Manager.
# This file is not loaded automatically. Source it from your own ~/.bashrc,
# or copy only the integrations you need.

if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --bash)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

if command -v yazi >/dev/null 2>&1; then
  yy() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXX)"
    command yazi "$@" --cwd-file="$tmp"
    if cwd="$(<"$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
      builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
  }
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
fi
