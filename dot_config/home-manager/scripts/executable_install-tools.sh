#!/usr/bin/env bash
set -euo pipefail

CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
CARGO_BIN="$CARGO_HOME/bin"
export CARGO_HOME
export PATH="$CARGO_BIN:$PATH"

if ! command -v cargo >/dev/null 2>&1; then
  printf 'error: cargo is not available in PATH\n' >&2
  exit 1
fi

mkdir -p "$CARGO_BIN"

if [[ ! -x "$CARGO_BIN/cargo-binstall" ]]; then
  printf 'Installing cargo-binstall...\n'
  cargo install --locked cargo-binstall
else
  printf 'Already installed: cargo-binstall\n'
fi

install_crate() {
  local crate="$1"
  shift

  local binary
  for binary in "$@"; do
    if [[ ! -x "$CARGO_BIN/$binary" ]]; then
      printf 'Installing %s...\n' "$crate"
      if ! cargo binstall --no-confirm "$crate"; then
        printf 'No prebuilt package available; compiling %s...\n' "$crate"
        cargo install --locked "$crate"
      fi
      return
    fi
  done

  printf 'Already installed: %s\n' "$crate"
}

install_crate cargo-update cargo-install-update
install_crate yazi-build yazi ya
install_crate zellij zellij
install_crate ripgrep rg
install_crate fd-find fd

printf '\nCargo tools are available in %s:\n' "$CARGO_BIN"
for binary in cargo-binstall cargo-install-update yazi ya zellij rg fd; do
  if [[ -x "$CARGO_BIN/$binary" ]]; then
    printf '  %-22s %s\n' "$binary" "$CARGO_BIN/$binary"
  else
    printf '  %-22s missing\n' "$binary"
  fi
done
