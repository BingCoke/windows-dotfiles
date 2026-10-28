{ config, pkgs, ... }:

let
  xdgDesktopPortalWlr = pkgs.xdg-desktop-portal-wlr.overrideAttrs (_: {
    version = "0.9.0-dev-2e67398";
    src = pkgs.fetchFromGitHub {
      owner = "emersion";
      repo = "xdg-desktop-portal-wlr";
      rev = "2e67398bd492392c258b680f4d2a1f371356c1e1";
      hash = "sha256-TBzGR8EAvOjBY6os2wt9vP97y4Eh4U9VWmcZ2871yDM=";
    };
  });

  niriSession = pkgs.writeTextFile {
    name = "nix-niri-session";
    destination = "/share/wayland-sessions/nix-niri.desktop";
    text = ''
      [Desktop Entry]
      Name=Nix Niri
      Comment=Niri compositor from the Nix profile
      Exec=${config.home.homeDirectory}/.nix-profile/bin/niri-session
      DesktopNames=niri;
      Type=Application
    '';
  };

  startNiri = pkgs.writeShellScriptBin "start-niri" ''
    XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=niri exec ${pkgs.niri}/bin/niri-session
  '';

  niriDesktop = pkgs.writeShellScriptBin "niri-desktop" ''
    set -eu

    session_file="${config.home.homeDirectory}/.nix-profile/share/wayland-sessions/nix-niri.desktop"
    target_file="/usr/share/wayland-sessions/nix-niri.desktop"

    usage() {
      printf 'Usage: niri-desktop {install|uninstall}\n' >&2
      exit 2
    }

    [ "$#" -eq 1 ] || usage

    case "$1" in
      install)
        if [ ! -f "$session_file" ]; then
          printf 'Nix Niri session file not found: %s\n' "$session_file" >&2
          printf 'Run home-manager switch first.\n' >&2
          exit 1
        fi
        exec /usr/bin/sudo -- ${pkgs.coreutils}/bin/install -Dm644 \
          "$session_file" "$target_file"
        ;;
      uninstall)
        exec /usr/bin/sudo -- ${pkgs.coreutils}/bin/rm -f "$target_file"
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

  imports = [ ./niri.nix ];

  home.file = {
    ".config/systemd/user/xdg-desktop-portal.service".source =
      "${pkgs.xdg-desktop-portal}/share/systemd/user/xdg-desktop-portal.service";
    ".config/systemd/user/xdg-desktop-portal-wlr.service".source =
      "${xdgDesktopPortalWlr}/share/systemd/user/xdg-desktop-portal-wlr.service";
  };

  xdg.portal.extraPortals = [ xdgDesktopPortalWlr ];

  home.packages = [
    niriSession
    startNiri
    niriDesktop
    pkgs.noctalia
    noctaliaHostAuth
  ];
}
