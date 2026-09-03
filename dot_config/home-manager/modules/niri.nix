{ lib, pkgs, xdgDesktopPortalWlr, ... }:

let
  xwaylandSatellite = pkgs.xwayland-satellite;
  patchedXwaylandSatellite = xwaylandSatellite.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ../patches/xwayland-satellite-dingtalk-popup.patch
    ];
  });
in
{
  home.file.".config/systemd/user/niri.service.wants/xdg-desktop-portal-wlr.service".source =
    "${xdgDesktopPortalWlr}/share/systemd/user/xdg-desktop-portal-wlr.service";

  wayland.windowManager.niri = {
    enable = true;
    xwaylandSatellitePackage =
      assert lib.assertMsg (xwaylandSatellite.version == "0.8.2")
        "xwayland-satellite changed from 0.8.2; verify whether the DingTalk popup patch is still needed before updating it";
      patchedXwaylandSatellite;
  };

  xdg.portal.config.niri = {
    default = [ "gtk" ];
    "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
    "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
  };
}
