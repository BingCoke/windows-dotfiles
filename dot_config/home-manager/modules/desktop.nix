{ lib, pkgs, ... }:

let
  codeMimeTypes = [
    "text/plain"
    "text/x-python"
    "application/x-shellscript"
    "application/x-fishscript"
    "text/x-csrc"
    "text/x-chdr"
    "text/x-c++src"
    "text/x-c++hdr"
    "text/rust"
    "text/x-go"
    "text/x-java"
    "text/javascript"
    "text/vnd.trolltech.linguist"
    "application/json"
    "application/toml"
    "application/yaml"
    "text/x-lua"
    "text/x-makefile"
    "application/x-ruby"
    "application/x-php"
    "text/css"
  ];
in
{
  imports = [
    ./compositors.nix
    ./wayland.nix
    ./input-method.nix
    ./fonts.nix
  ];

  targets.genericLinux.enable = true;

  xdg.desktopEntries.kitty-nvim = {
    name = "Neovim (Kitty)";
    exec = "${pkgs.kitty}/bin/kitty ${pkgs.neovim}/bin/nvim %F";
    terminal = false;
    noDisplay = true;
    mimeType = codeMimeTypes;
  };

  home.activation.setMimeDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.xdg-utils}/bin/xdg-mime default thunar.desktop inode/directory
    ${lib.concatMapStringsSep "\n" (mimeType: "${pkgs.xdg-utils}/bin/xdg-mime default kitty-nvim.desktop ${mimeType}") codeMimeTypes}
  '';

  home.packages = [
    pkgs.thunar
    pkgs.xdg-user-dirs
    # GTK3/GTK4 theme used by Noctalia's GTK templates.
    pkgs.adw-gtk3

    # Qt5 and Qt6 theme selectors for Noctalia-generated color schemes.
    pkgs.libsForQt5.qt5ct
    pkgs.qt6Packages.qt6ct

    # GTK theme selector and first-run cleanup tool.
    pkgs.nwg-look
  ];

  # Qt6 is the default for current applications. Qt5 applications can be
  # launched with QT_QPA_PLATFORMTHEME=qt5ct when needed.
  home.sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";
}
