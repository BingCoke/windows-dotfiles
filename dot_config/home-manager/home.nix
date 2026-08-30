{ pkgs, ... }:

{
  imports = [
    ./modules/neovim.nix
    ./modules/development.nix
  ];

  home.stateVersion = "24.05";


  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    git
  ];
}
