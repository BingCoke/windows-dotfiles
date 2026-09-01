{ pkgs, ... }:

{
  programs.mise = {
    enable = true;
    enableFishIntegration = true;
  };

  home.packages = with pkgs; [
    cargo
    fnm
    go
    lazygit
    rustc
    uv
    nixd
  ];
}
