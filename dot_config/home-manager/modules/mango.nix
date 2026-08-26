{ pkgs, nixgl, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;

  mangoDirect = pkgs.runCommand "mango-direct" {} ''
    mkdir -p "$out/bin"
    ln -s ${pkgs.mango}/bin/mango "$out/bin/mango-direct"
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
    # Nix Mango needs the host EGL bridge on non-NixOS systems.
    (pkgs.writeShellScriptBin "mango" ''
      exec ${nixgl.packages.${system}.nixGLDefault}/bin/nixGL \
        ${pkgs.mango}/bin/mango "$@"
    '')

    # Direct binary for diagnosing host graphics integration.
    mangoDirect

    # Noctalia inherits the graphics environment from the Mango session.
    pkgs.noctalia
    noctaliaHostAuth
  ];
}
