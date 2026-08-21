{ pkgs, ... }:

{
  home.packages = with pkgs; [
    go
    fnm
    uv
    lazygit
  ];
}
