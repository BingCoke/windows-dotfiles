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
  wayland.windowManager.niri = {
    enable = true;
    xwaylandSatellitePackage =
      assert lib.assertMsg (xwaylandSatellite.version == "0.8.2")
        "xwayland-satellite changed from 0.8.2; verify whether the DingTalk popup patch is still needed before updating it";
      patchedXwaylandSatellite;
  };
}
