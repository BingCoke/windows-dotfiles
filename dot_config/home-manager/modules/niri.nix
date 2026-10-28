{ pkgs, xdgDesktopPortalWlr, ... }:

let
  xwaylandSatelliteRevision = "45b912c6fbcbbc9bc22148c865e95a449d3b5c0e";
  xwaylandSatelliteSrc = pkgs.fetchFromGitHub {
    owner = "Supreeeme";
    repo = "xwayland-satellite";
    rev = xwaylandSatelliteRevision;
    hash = "sha256-LJdlM4zm7UyOC0fxBdV1im+Mi/vEO63hxe4kAR+/kO0=";
  };
  xwaylandSatellite = pkgs.xwayland-satellite.overrideAttrs (_: {
    version = "0.8.3-dev-45b912c";
    src = xwaylandSatelliteSrc;
    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      src = xwaylandSatelliteSrc;
      hash = "sha256-gyQmdkWxnoaJzW1KN40ZmRTjVbfpt6tA8JHUMds35ag=";
    };
  });
  patchedXwaylandSatellite = xwaylandSatellite.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ../patches/xwayland-satellite-icccm-focus.patch
      ../patches/xwayland-satellite-dingtalk-popup.patch
      ../patches/xwayland-satellite-input-region-scale.patch
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
