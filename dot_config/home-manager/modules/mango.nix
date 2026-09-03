{ pkgs, ... }:

{
  home.packages = [ pkgs.mango ];

  xdg.portal.config.mango = {
    default = [ "gtk" ];
    "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
    "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
  };
}
