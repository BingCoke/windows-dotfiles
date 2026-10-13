{ pkgs, ... }:

let
  pipewireUnits = pkgs.runCommand "pipewire-user-units" { } ''
    mkdir -p "$out"
    cp ${pkgs.pipewire}/share/systemd/user/{pipewire.service,pipewire.socket,pipewire-pulse.service,pipewire-pulse.socket,filter-chain.service} "$out/"
    substituteInPlace "$out/pipewire-pulse.service" "$out/filter-chain.service" \
      --replace-fail pipewire-session-manager.service wireplumber.service
  '';
  wireplumberUnit = "${pkgs.wireplumber}/share/systemd/user/wireplumber.service";
in
{
  home.packages = [
    pkgs.pipewire
    pkgs.wireplumber
    pkgs.pavucontrol
    pkgs.pamixer
    pkgs.playerctl
  ];

  xdg.configFile = {
    "systemd/user/pipewire.service".source = "${pipewireUnits}/pipewire.service";
    "systemd/user/pipewire.socket".source = "${pipewireUnits}/pipewire.socket";
    "systemd/user/pipewire-pulse.service".source = "${pipewireUnits}/pipewire-pulse.service";
    "systemd/user/pipewire-pulse.socket".source = "${pipewireUnits}/pipewire-pulse.socket";
    "systemd/user/filter-chain.service".source = "${pipewireUnits}/filter-chain.service";
    "systemd/user/wireplumber.service".source = wireplumberUnit;

    "systemd/user/default.target.wants/pipewire.service".source = "${pipewireUnits}/pipewire.service";
    "systemd/user/default.target.wants/pipewire-pulse.service".source = "${pipewireUnits}/pipewire-pulse.service";
    "systemd/user/default.target.wants/filter-chain.service".source = "${pipewireUnits}/filter-chain.service";
    "systemd/user/sockets.target.wants/pipewire.socket".source = "${pipewireUnits}/pipewire.socket";
    "systemd/user/sockets.target.wants/pipewire-pulse.socket".source = "${pipewireUnits}/pipewire-pulse.socket";
    "systemd/user/pipewire.service.wants/wireplumber.service".source = wireplumberUnit;
  };
}
