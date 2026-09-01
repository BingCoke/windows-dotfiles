{ pkgs, ... }:

{
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  home.packages = with pkgs; [
    kitty
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
