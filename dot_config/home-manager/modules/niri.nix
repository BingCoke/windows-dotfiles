{ pkgs, xdgDesktopPortalWlr, ... }:

let
  xwaylandSatelliteRevision = "add2795134593faafce60e404a0a75df68e9ee0c";
  xwaylandSatelliteSrc = pkgs.fetchFromGitHub {
    owner = "Supreeeme";
    repo = "xwayland-satellite";
    rev = xwaylandSatelliteRevision;
    hash = "sha256-0TxfMgqW0/BLD4M942c5DCKYrtPvzsPJwvdcco4LQUM=";
  };
  xwaylandSatellite = pkgs.xwayland-satellite.overrideAttrs (_: {
    src = xwaylandSatelliteSrc;
    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      src = xwaylandSatelliteSrc;
      hash = "sha256-s1gl9eR6Mt2QLrhfcowstPFjzwE/lz4PJhJzWYHoIHg=";
    };
  });
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
    xwaylandSatellitePackage = patchedXwaylandSatellite;
  };

  xdg.portal.config.niri = {
    default = [ "gtk" ];
    "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
    "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
  };
}
