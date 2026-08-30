{ config, pkgs, ... }:

let
  mangoSession = pkgs.writeTextFile {
    name = "nix-mango-session";
    destination = "/share/wayland-sessions/nix-mango.desktop";
    text = ''
      [Desktop Entry]
      Name=Nix Mango
      Comment=Mango WM from the Nix profile
      Exec=${config.home.homeDirectory}/.nix-profile/bin/mango
      TryExec=${config.home.homeDirectory}/.nix-profile/bin/mango
      DesktopNames=mango;wlroots;
      Type=Application
    '';
  };

  mangoDesktop = pkgs.writeShellScriptBin "mango-desktop" ''
    set -eu

    session_file="${config.home.homeDirectory}/.nix-profile/share/wayland-sessions/nix-mango.desktop"
    target="/usr/share/wayland-sessions/nix-mango.desktop"

    usage() {
      printf 'Usage: mango-desktop {install|uninstall}\n' >&2
      exit 2
    }

    [ "$#" -eq 1 ] || usage

    case "$1" in
      install)
        if [ ! -f "$session_file" ]; then
          printf 'Nix Mango session file not found: %s\n' "$session_file" >&2
          printf 'Run home-manager switch first.\n' >&2
          exit 1
        fi
        exec /usr/bin/sudo -- ${pkgs.coreutils}/bin/install -Dm644 \
          "$session_file" "$target"
        ;;
      uninstall)
        exec /usr/bin/sudo -- ${pkgs.coreutils}/bin/rm -f "$target"
        ;;
      *)
        usage
        ;;
    esac
  '';

  # Host authentication crosses the root boundary and stays explicit.
  noctaliaHostAuth = pkgs.writeShellScriptBin "noctalia-host-auth" ''
    if [ "$(id -u)" -ne 0 ]; then
      case "$1" in
        install|remove)
          exec /usr/bin/sudo -- ${pkgs.bash}/bin/bash ${../scripts/noctalia-host-auth.sh} "$@"
          ;;
      esac
    fi
    exec ${pkgs.bash}/bin/bash ${../scripts/noctalia-host-auth.sh} "$@"
  '';

in {
  home.packages = [
    pkgs.mango

    # GDM reads session entries from /usr/share/wayland-sessions.
    mangoSession
    mangoDesktop

    # Noctalia inherits the graphics environment from the Mango session.
    pkgs.noctalia
    noctaliaHostAuth
  ];
}
