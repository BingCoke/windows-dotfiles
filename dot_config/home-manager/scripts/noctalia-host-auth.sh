#!/usr/bin/env bash
set -euo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

program=${0##*/}
config=/etc/tmpfiles.d/noctalia-host-auth.conf
unix_link=/run/wrappers/bin/unix_chkpwd
polkit_link=/run/wrappers/bin/polkit-agent-helper-1
socket_unit=polkit-agent-helper.socket

usage() {
  cat <<EOF
Usage: $program <build-pam|check|install|test|remove>

  build-pam  Build the lock-screen helper with the host compiler and PAM
  check      Show PAM helper and host bridge readiness
  install    Configure the host bridge (asks for sudo)
  test       Open one harmless polkit authentication prompt
  remove     Remove links managed by this tool (asks for sudo)
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_root() {
  [[ $EUID -eq 0 ]] || die "run '$program $1' with sudo"
}

system_profile() {
  [[ -r /etc/os-release ]] || die '/etc/os-release was not found'

  local ID='' ID_LIKE=''
  # shellcheck disable=SC1091
  source /etc/os-release

  case " ${ID:-} ${ID_LIKE:-} " in
    *' nixos '*) printf 'nixos\n' ;;
    *' fedora '*|*' rhel '*) printf 'fedora\n' ;;
    *' arch '*) printf 'arch\n' ;;
    *' ubuntu '*|*' debian '*) printf 'ubuntu\n' ;;
    *) printf 'unsupported\n' ;;
  esac
}

package_owns() {
  local path=$1

  if command -v rpm >/dev/null 2>&1; then
    rpm -qf "$path" >/dev/null 2>&1
  elif command -v pacman >/dev/null 2>&1; then
    pacman -Qo "$path" >/dev/null 2>&1
  elif command -v dpkg-query >/dev/null 2>&1; then
    dpkg-query -S "$path" >/dev/null 2>&1
  else
    return 1
  fi
}

validate_helper() {
  local path=$1 required_bits=$2 target mode permissions

  target=$(readlink -f "$path" 2>/dev/null) || return 1
  [[ -f $target ]] || return 1
  [[ $(stat -c '%u' "$target") == 0 ]] || return 1

  mode=$(stat -c '%a' "$target")
  permissions=$((8#$mode))
  ((permissions & required_bits)) || return 1
  (((permissions & 0022) == 0)) || return 1
  package_owns "$target" || return 1
}

find_helper() {
  local required_bits=$1 candidate
  shift

  for candidate in "$@"; do
    if validate_helper "$candidate" "$required_bits"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

find_unix_helper() {
  # Ubuntu ships unix_chkpwd as setgid shadow (2755); other systems may use setuid.
  find_helper 06000 \
    /usr/sbin/unix_chkpwd \
    /usr/bin/unix_chkpwd \
    /sbin/unix_chkpwd
}

find_polkit_helper() {
  find_helper 04000 \
    /usr/lib/polkit-1/polkit-agent-helper-1 \
    /usr/libexec/polkit-1/polkit-agent-helper-1 \
    /usr/libexec/polkit-agent-helper-1
}

socket_available() {
  local fragment mode permissions
  command -v systemctl >/dev/null 2>&1 || return 1
  fragment=$(systemctl show -p FragmentPath --value "$socket_unit" 2>/dev/null) || return 1
  [[ -f $fragment ]] || return 1
  [[ $(stat -c '%u' "$fragment") == 0 ]] || return 1
  mode=$(stat -c '%a' "$fragment")
  permissions=$((8#$mode))
  (((permissions & 0022) == 0)) || return 1
  package_owns "$fragment"
}

socket_ready() {
  socket_available &&
    systemctl is-active --quiet "$socket_unit" &&
    [[ -S /run/polkit/agent-helper.socket ]]
}

link_matches() {
  local link=$1 target=$2
  [[ -L $link ]] && [[ $(readlink -f "$link") == "$(readlink -f "$target")" ]]
}

bridge_ready() {
  local unix_helper
  unix_helper=$(find_unix_helper) || return 1
  link_matches "$unix_link" "$unix_helper" || return 1

  if socket_ready; then
    return 0
  fi

  local polkit_helper
  polkit_helper=$(find_polkit_helper) || return 1
  link_matches "$polkit_link" "$polkit_helper"
}

build_pam_command() {
  [[ $EUID -ne 0 ]] || die 'run build-pam as the desktop user, without sudo'

  local profile build_dir
  profile=$(system_profile)
  [[ $profile != nixos ]] || die 'use the native NixOS polkit/PAM configuration'
  [[ $profile != unsupported ]] || die 'only Fedora, Arch, and Ubuntu/Debian are supported'
  [[ -n ${NOCTALIA_PAM_SOURCE:-} && -n ${NOCTALIA_PAM_HELPER_PATH:-} ]] ||
    die 'run the noctalia-host-auth command from the Home Manager profile'
  command -v c++ >/dev/null 2>&1 || die 'install the host C++ compiler; see docs/noctalia-host-auth.md'
  printf '#include <security/pam_appl.h>\n' | c++ -x c++ -E - >/dev/null 2>&1 ||
    die 'install the host PAM development package (Fedora: pam-devel; Ubuntu/Debian: libpam0g-dev)'

  build_dir=$(mktemp -d)
  trap 'rm -rf "${build_dir:-}"' EXIT
  c++ -std=c++23 -O2 -Wall -Wextra -Wpedantic \
    '-DNOCTALIA_PAM_SERVICE="login"' \
    -I "$NOCTALIA_PAM_SOURCE/src" \
    "$NOCTALIA_PAM_SOURCE/src/auth/pam_helper_main.cpp" \
    -lpam -o "$build_dir/noctalia-pam-helper"
  install -Dm755 "$build_dir/noctalia-pam-helper" "$NOCTALIA_PAM_HELPER_PATH"
  rm -rf "$build_dir"
  trap - EXIT
  printf 'Host PAM helper built: %s\nRestart Noctalia with NOCTALIA_PAM_HELPER_PATH set to this path.\n' \
    "$NOCTALIA_PAM_HELPER_PATH"
}

check_command() {
  local profile ready=true
  profile=$(system_profile)
  printf 'System: %s\n' "$profile"

  if [[ $profile == nixos ]]; then
    printf 'Status: use the native NixOS polkit/PAM configuration\n'
    return 1
  fi

  if [[ $profile == unsupported ]]; then
    printf 'Status: unsupported; follow docs/noctalia-host-auth.md\n'
    return 1
  fi

  if [[ -n ${NOCTALIA_PAM_HELPER_PATH:-} && -x $NOCTALIA_PAM_HELPER_PATH ]]; then
    printf 'Lock-screen PAM: ready (%s)\n' "$NOCTALIA_PAM_HELPER_PATH"
  else
    printf 'Lock-screen PAM: helper missing\nNext: %s build-pam\n' "$program"
    ready=false
  fi

  if bridge_ready; then
    if socket_ready; then
      printf 'Host bridge: ready (systemd polkit socket)\n'
    else
      printf 'Host bridge: ready (host helper bridge)\n'
    fi
  else
    printf 'Host bridge: not ready\nNext: %s install\n' "$program"
    ready=false
  fi

  "$ready"
}

ensure_link_available() {
  local link=$1 target=$2

  if [[ -L $link ]]; then
    link_matches "$link" "$target" || die "$link points to an unmanaged target"
  elif [[ -e $link ]]; then
    die "$link already exists and is not a symlink"
  fi
}

managed_link_target() {
  local link=$1
  [[ -f $config ]] || return 1
  grep -Fxq '# Managed by noctalia-host-auth' "$config" || return 1
  awk -v link="$link" '$1 == "L" && $2 == link { print $NF }' "$config"
}

write_tmpfiles_config() {
  local unix_helper=$1 polkit_helper=${2:-} tmp

  if [[ -e $config ]] && ! grep -Fxq '# Managed by noctalia-host-auth' "$config"; then
    die "$config exists but is not managed by this tool"
  fi

  tmp=$(mktemp "${config}.XXXXXX")
  trap 'rm -f "${tmp:-}"' EXIT
  {
    printf '%s\n' '# Managed by noctalia-host-auth'
    printf '%s\n' 'd /run/wrappers 0755 root root -'
    printf '%s\n' 'd /run/wrappers/bin 0755 root root -'
    printf 'L %s - - - - %s\n' "$unix_link" "$unix_helper"
    if [[ -n $polkit_helper ]]; then
      printf 'L %s - - - - %s\n' "$polkit_link" "$polkit_helper"
    fi
  } >"$tmp"
  chmod 0644 "$tmp"
  mv -f "$tmp" "$config"
  trap - EXIT
}

install_command() {
  require_root install

  local profile unix_helper polkit_helper='' old_polkit_target='' mode
  profile=$(system_profile)
  [[ $profile != nixos ]] || die 'use the native NixOS polkit/PAM configuration'
  [[ $profile != unsupported ]] || die 'only Fedora, Arch, and Ubuntu/Debian are supported'
  command -v systemd-tmpfiles >/dev/null 2>&1 || die 'systemd-tmpfiles is required'

  unix_helper=$(find_unix_helper) || die 'a trusted host unix_chkpwd was not found'
  ensure_link_available "$unix_link" "$unix_helper"

  if [[ -f $config ]]; then
    grep -Fxq '# Managed by noctalia-host-auth' "$config" || die "$config is not managed by this tool"
    old_polkit_target=$(managed_link_target "$polkit_link" || true)
  fi

  if socket_available; then
    mode=socket
  else
    mode=wrapper
    polkit_helper=$(find_polkit_helper) || die 'a trusted host polkit-agent-helper-1 was not found'
    ensure_link_available "$polkit_link" "$polkit_helper"
  fi

  write_tmpfiles_config "$unix_helper" "$polkit_helper"
  if [[ $mode == socket && -n $old_polkit_target ]] &&
    [[ -L $polkit_link ]] && [[ $(readlink "$polkit_link") == "$old_polkit_target" ]]; then
    rm -f "$polkit_link"
  fi
  systemd-tmpfiles --create "$config"

  if [[ $mode == socket ]]; then
    systemctl enable --now "$socket_unit"
  fi

  bridge_ready || die 'installation completed but verification failed'
  printf 'Host authentication is ready.\nNext: %s test\n' "$program"
}

noctalia_pid() {
  pgrep -f '(^|/)noctalia($| )' 2>/dev/null | head -n 1
}

selinux_blocked_auth() {
  command -v journalctl >/dev/null 2>&1 || return 1
  journalctl -b --since '-2 min' --no-pager 2>/dev/null |
    grep -Eq 'avc:  denied.*(nnp_transition|execute_no_trans).*polkit-agent|avc:  denied.*execute_no_trans.*unix_chkpwd'
}

test_command() {
  bridge_ready || die "run '$program install' first"
  command -v pkexec >/dev/null 2>&1 || die 'pkexec was not found'

  local before='' after=''
  before=$(noctalia_pid || true)
  [[ -n $before ]] || die 'Noctalia is not running'

  printf 'An authentication prompt will open. No system change will be made.\n'
  if ! pkexec --disable-internal-agent /usr/bin/true; then
    if selinux_blocked_auth; then
      die 'SELinux blocked authentication; update the host SELinux policy and test again'
    fi
    die 'authentication failed; check the password and system journal'
  fi

  after=$(noctalia_pid || true)
  [[ $after == "$before" ]] || die 'authentication finished, but Noctalia exited or restarted'
  printf 'Polkit authentication test passed. Test lock-screen unlocking separately.\n'
}

remove_command() {
  require_root remove

  if [[ ! -f $config ]]; then
    printf 'Nothing to remove.\n'
    return 0
  fi
  grep -Fxq '# Managed by noctalia-host-auth' "$config" || die "$config is not managed by this tool"

  local link target
  while read -r link target; do
    if [[ -L $link ]] && [[ $(readlink "$link") == "$target" ]]; then
      rm -f "$link"
    fi
  done < <(awk '$1 == "L" { print $2, $NF }' "$config")

  rm -f "$config"
  printf 'Managed helper links were removed. The host polkit socket was left enabled.\n'
}

case ${1:-} in
  build-pam) build_pam_command ;;
  check) check_command ;;
  install) install_command ;;
  test) test_command ;;
  remove) remove_command ;;
  -h|--help|help|'') usage ;;
  *) usage >&2; exit 2 ;;
esac
