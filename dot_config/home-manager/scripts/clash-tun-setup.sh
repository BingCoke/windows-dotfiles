#!/usr/bin/env bash
set -euo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

(($# == 2)) || die 'usage: clash-tun-setup'
[[ $EUID -eq 0 ]] || die 'clash-tun-setup must run as root'

service_binary=$1
service_user=$2
service=clash-verge.service
unit=/etc/systemd/system/$service
socket=/run/clash-verge-rev/service.sock
marker='# Managed by Home Manager: clash-tun-setup'

[[ -x $service_binary ]] || die "Clash Verge service was not found: $service_binary; run home-manager switch first"

if [[ -e $unit || -L $unit ]]; then
  grep -Fxq "$marker" "$unit" || die "$unit exists and is not managed by clash-tun-setup"
fi

service_group=$(id -gn "$service_user") || die "user does not exist: $service_user"

tmp=$(mktemp /etc/systemd/system/.clash-verge.service.XXXXXX)
trap 'rm -f "$tmp"' EXIT
cat >"$tmp" <<EOF
$marker
[Unit]
Description=Clash Verge Service
After=network.target

[Service]
Type=simple
User=root
Group=$service_group
ExecStart=$service_binary
Restart=on-failure
RestartSec=2s
RuntimeDirectory=clash-verge-rev
RuntimeDirectoryMode=0750
StateDirectory=clash-verge-service
StateDirectoryMode=0700
Environment=XDG_STATE_HOME=/var/lib
UMask=0007

[Install]
WantedBy=multi-user.target
EOF
chmod 0644 "$tmp"
mv -f "$tmp" "$unit"
trap - EXIT

systemctl daemon-reload
systemctl enable "$service" >/dev/null
systemctl restart "$service"

for ((attempt = 0; attempt < 50; attempt++)); do
  if ! systemctl is-active --quiet "$service"; then
    systemctl --no-pager --full status "$service" || true
    die "Clash Verge service failed to start; check: sudo journalctl -u $service -b"
  fi
  if [[ -S $socket ]]; then
    printf 'Clash Verge TUN service is ready. Restart Clash Verge, then enable TUN in its settings.\n'
    exit 0
  fi
  sleep 0.1
done

die "Clash Verge service socket is not ready; check: sudo journalctl -u $service -b"
