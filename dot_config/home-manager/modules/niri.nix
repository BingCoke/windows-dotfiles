{ pkgs, xdgDesktopPortalWlr, ... }:

let
  xwaylandSatelliteRevision = "b83eab900644e4c7c77982ce3d44cb490f0c5e1d";
  xwaylandSatelliteSrc = pkgs.fetchFromGitHub {
    owner = "Supreeeme";
    repo = "xwayland-satellite";
    rev = xwaylandSatelliteRevision;
    hash = "sha256-eFEjCCniMCKeWU0PcZNv+tDYe08SLFPjRplyPY8OFt4=";
  };
  xwaylandSatellite = pkgs.xwayland-satellite.overrideAttrs (_: {
    version = "0.8.3";
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
