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

  # Flatpak remaps XDG_DATA_HOME; client-side candidate windows load themes
  # from there via xdg-data/fcitx5, not from ~/.nix-profile.
  xdg.dataFile."fcitx5/themes/catppuccin-mocha-teal".source =
    "${pkgs.catppuccin-fcitx5}/share/fcitx5/themes/catppuccin-mocha-teal";
}
