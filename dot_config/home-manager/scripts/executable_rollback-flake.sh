#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
backup="$root/flake.lock.before-nixpkgs-update"

if [[ ! -f "$backup" ]]; then
  echo "Backup not found: $backup" >&2
  exit 1
fi

cp -- "$backup" "$root/flake.lock"
echo "Restored $root/flake.lock from $backup"
