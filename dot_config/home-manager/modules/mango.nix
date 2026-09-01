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

}
