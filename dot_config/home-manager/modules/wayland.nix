{ pkgs, ... }:

{
  home.packages = with pkgs; [
    wezterm
    poweralertd
    wl-clipboard
    satty
    wdisplays
    wlr-randr
    kanshi
    brightnessctl
    ddcutil
    ddcutil-service
    vdu_controls
    pavucontrol
    pamixer
    playerctl
    lxqt.lxqt-policykit
    libnotify
    xdg-utils
    wayvnc
    wev
    xrdb
  ];
}
