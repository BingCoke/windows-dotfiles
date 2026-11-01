{ pkgs, ... }:

let
  fcitx5Rime = pkgs.fcitx5-rime.override {
    rimeDataPkgs = [ pkgs.rime-ice ];
  };
in
{
  home.packages = [
    (pkgs.qt6Packages.fcitx5-with-addons.override {
      addons = [
        pkgs.qt6Packages.fcitx5-chinese-addons
        fcitx5Rime
        pkgs.fcitx5-lua
        pkgs.catppuccin-fcitx5
      ];
    })
  ];

  # Make Rime's schemas and dictionaries available to Fcitx5-Rime.
  xdg.dataFile."fcitx5/rime/default.custom.yaml".text = ''
    patch:
      __include: rime_ice_suggestion:/
  '';

  # Flatpak remaps XDG_DATA_HOME; client-side candidate windows load themes
  # from there via xdg-data/fcitx5, not from ~/.nix-profile.
  xdg.dataFile."fcitx5/themes/catppuccin-mocha-teal".source =
    "${pkgs.catppuccin-fcitx5}/share/fcitx5/themes/catppuccin-mocha-teal";
}
