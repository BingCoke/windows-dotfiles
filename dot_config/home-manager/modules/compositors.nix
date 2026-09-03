{ config, pkgs, ... }:

let
  xdgDesktopPortalWlr = pkgs.xdg-desktop-portal-wlr.overrideAttrs (_: {
    version = "0.9.0-dev-c0255d7";
    src = pkgs.fetchFromGitHub {
      owner = "emersion";
      repo = "xdg-desktop-portal-wlr";
      rev = "c0255d7b047b7263629ab5a314661045ff7f65e3";
      hash = "sha256-W+0FrP5dlmf/dxcXt6pv4HFbpvJABNRl4TEghCSIy9c=";
    };
  });

  mkSession = { name, displayName, comment, command, desktopNames }:
    pkgs.writeTextFile {
      name = "nix-${name}-session";
      destination = "/share/wayland-sessions/nix-${name}.desktop";
      text = ''
        [Desktop Entry]
        Name=${displayName}
        Comment=${comment}
        Exec=${config.home.homeDirectory}/.nix-profile/bin/${command}
        TryExec=${config.home.homeDirectory}/.nix-profile/bin/${command}
        DesktopNames=${desktopNames}
        Type=Application
      '';
    };

  mangoSession = mkSession {
    name = "mango";
    displayName = "Nix Mango";
    comment = "Mango WM from the Nix profile";
    command = "mango";
    desktopNames = "mango;wlroots;";
  };

  niriSession = mkSession {
    name = "niri";
    displayName = "Nix Niri";
    comment = "Niri compositor from the Nix profile";
    command = "niri-session";
    desktopNames = "niri;";
  };

  startNiri = pkgs.writeShellScriptBin "start-niri" ''
    XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=niri exec ${pkgs.niri}/bin/niri-session
  '';

  compositorDesktop = pkgs.writeShellScriptBin "compositor-desktop" ''
    set -eu

    session_dir="${config.home.homeDirectory}/.nix-profile/share/wayland-sessions"
    target_dir="/usr/share/wayland-sessions"
    mango="$session_dir/nix-mango.desktop"
    niri="$session_dir/nix-niri.desktop"

    usage() {
      printf 'Usage: compositor-desktop {install|uninstall}\n' >&2
      exit 2
    }

    [ "$#" -eq 1 ] || usage

    case "$1" in
      install)
        for session_file in "$mango" "$niri"; do
          if [ ! -f "$session_file" ]; then
            printf 'Nix compositor session file not found: %s\n' "$session_file" >&2
            printf 'Run home-manager switch first.\n' >&2
            exit 1
          fi
        done
        exec /usr/bin/sudo -- ${pkgs.coreutils}/bin/install -Dm644 \
          -t "$target_dir" "$mango" "$niri"
        ;;
      uninstall)
        exec /usr/bin/sudo -- ${pkgs.coreutils}/bin/rm -f \
          "$target_dir/nix-mango.desktop" "$target_dir/nix-niri.desktop"
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
  _module.args = { inherit xdgDesktopPortalWlr; };

  imports = [
    ./mango.nix
    ./niri.nix
  ];

  home.file = {
    ".config/systemd/user/xdg-desktop-portal.service".source =
      "${pkgs.xdg-desktop-portal}/share/systemd/user/xdg-desktop-portal.service";
    ".config/systemd/user/xdg-desktop-portal-wlr.service".source =
      "${xdgDesktopPortalWlr}/share/systemd/user/xdg-desktop-portal-wlr.service";
  };

  xdg.portal.extraPortals = [ xdgDesktopPortalWlr ];

  home.packages = [
    mangoSession
    niriSession
    startNiri
    compositorDesktop
    pkgs.noctalia
    noctaliaHostAuth
  ];
}
