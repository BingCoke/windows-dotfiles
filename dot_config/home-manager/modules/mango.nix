{ pkgs, mangobar, nixgl, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in {
  home.packages = [
    pkgs.mango
    mangobar.packages.${system}.default
    nixgl.packages.${system}.nixGLIntel
    pkgs.rofi
    pkgs.wezterm
  ];
}
