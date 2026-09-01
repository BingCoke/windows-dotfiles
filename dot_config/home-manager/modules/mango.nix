{ pkgs, ... }:

{
  home.packages = [ pkgs.mango ];

  xdg.portal = {
    extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
    config.mango = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
    };
  };

  systemd.user.services."xdg-desktop-portal-wlr" = {
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
}
