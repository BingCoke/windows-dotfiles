{ pkgs, ... }:

{
  imports = [
    ./mango.nix
    ./wayland.nix
    ./input-method.nix
    ./fonts.nix
  ];

  home.packages = [
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
