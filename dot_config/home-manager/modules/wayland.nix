{ pkgs, ... }:

{
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  home.file.".config/systemd/user/xdg-desktop-portal-gtk.service".source =
    "${pkgs.xdg-desktop-portal-gtk}/share/systemd/user/xdg-desktop-portal-gtk.service";

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
