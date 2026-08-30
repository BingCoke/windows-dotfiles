{ pkgs, ... }:

{
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
    config.mango = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
    };
  };

  systemd.user.services = {
    "xdg-desktop-portal" = {
      Unit = {
        Description = "Portal service";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.portal.Desktop";
        ExecStart = "${pkgs.xdg-desktop-portal}/libexec/xdg-desktop-portal";
        Slice = "session.slice";
      };
    };

    "xdg-desktop-portal-gtk" = {
      Unit = {
        Description = "Portal service (GTK/GNOME implementation)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.impl.portal.desktop.gtk";
        ExecStart = "${pkgs.xdg-desktop-portal-gtk}/libexec/xdg-desktop-portal-gtk";
      };
    };

    "xdg-desktop-portal-wlr" = {
      Unit = {
        Description = "Portal service (wlroots implementation)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.impl.portal.desktop.wlr";
        ExecStart = "${pkgs.xdg-desktop-portal-wlr}/libexec/xdg-desktop-portal-wlr";
        Restart = "on-failure";
      };
    };
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
