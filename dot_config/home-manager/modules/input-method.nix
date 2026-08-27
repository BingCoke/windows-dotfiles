{ pkgs, ... }:

{
  home.packages = [
    (pkgs.qt6Packages.fcitx5-with-addons.override {
      addons = [
        pkgs.qt6Packages.fcitx5-chinese-addons
        pkgs.fcitx5-lua
        pkgs.catppuccin-fcitx5
      ];
    })
  ];
}
