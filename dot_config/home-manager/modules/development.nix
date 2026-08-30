{ pkgs, ... }:

{
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
