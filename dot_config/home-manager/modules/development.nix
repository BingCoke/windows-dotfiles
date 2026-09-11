{ pkgs, ... }:

{
  programs.mise = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.emacs.enable = true;
  services.emacs.enable = true;

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
