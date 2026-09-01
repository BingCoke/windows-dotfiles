{ lib, pkgs, ... }:

let
  xwaylandSatellite = pkgs.xwayland-satellite;
  patchedXwaylandSatellite = xwaylandSatellite.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ../patches/xwayland-satellite-dingtalk-popup.patch
    ];
  });
in
{
  home.file = {
    ".config/systemd/user/xdg-desktop-portal-gnome.service".source =
      "${pkgs.xdg-desktop-portal-gnome}/share/systemd/user/xdg-desktop-portal-gnome.service";
    ".config/systemd/user/niri.service.wants/xdg-desktop-portal-gnome.service".source =
      "${pkgs.xdg-desktop-portal-gnome}/share/systemd/user/xdg-desktop-portal-gnome.service";
  };

  wayland.windowManager.niri = {
    enable = true;
    xwaylandSatellitePackage =
      assert lib.assertMsg (xwaylandSatellite.version == "0.8.2")
        "xwayland-satellite changed from 0.8.2; verify whether the DingTalk popup patch is still needed before updating it";
      patchedXwaylandSatellite;
  };

  xdg.portal = {
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-wlr
    ];
    config.niri = {
      default = [ "gnome" "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
      "org.freedesktop.impl.portal.RemoteDesktop" = [ "gnome" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
    };
  };
}
