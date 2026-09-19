{ pkgs, ... }:

{
  programs.fzf.enable = true;
  programs.mise.enable = true;
  programs.starship.enable = true;
  programs.yazi.enable = true;
  programs.zoxide.enable = true;

  programs.emacs.enable = true;
  services.emacs.enable = true;

  home.packages = with pkgs; [
    cargo
    lazygit
    rustc
    uv
    nixd
  ];
}
