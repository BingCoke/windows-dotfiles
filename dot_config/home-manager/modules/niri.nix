{ pkgs, xdgDesktopPortalWlr, ... }:

let
  xwaylandSatelliteRevision = "ae88928f7334556d298b8d9552abdf395931931b";
  xwaylandSatelliteSrc = pkgs.fetchFromGitHub {
    owner = "Supreeeme";
    repo = "xwayland-satellite";
    rev = xwaylandSatelliteRevision;
    hash = "sha256-+RlIyHipr7BOLsIC9jnpzbkLBsY6XbLhuPinAwJsYjo=";
  };
  xwaylandSatellite = pkgs.xwayland-satellite.overrideAttrs (_: {
    version = "0.8.3-dev-ae88928";
    src = xwaylandSatelliteSrc;
    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      src = xwaylandSatelliteSrc;
      hash = "sha256-gMGFvnbxM3hD5fmkSimaFd87GEf6BXFe/MGjoS6VNVU=";
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
