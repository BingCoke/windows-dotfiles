{ config, lib, pkgs, ... }:

let
  flatpakDataDir = "${config.xdg.dataHome}/flatpak/exports/share";

  # systemd environment.d files do not perform shell expansion. Keep the
  # concrete, host-specific directories supplied by targets.genericLinux and
  # omit entries such as `${NIX_STATE_DIR:-...}` that systemd cannot expand.
  systemdDataDirs = builtins.filter
    (directory: !(lib.hasInfix "$" directory))
    config.xdg.systemDirs.data;
in
{
  home.packages = [ pkgs.flatpak ];

  xdg.systemDirs.data = [ flatpakDataDir ];

  systemd.user.sessionVariables.XDG_DATA_DIRS = lib.mkForce (
    lib.concatStringsSep ":" systemdDataDirs
  );

  services.flatpak.enable = true;

  # nix-flatpak starts this oneshot from sd-switch and from an activation hook.
  # Both wait, so `home-manager switch` blocks on Flathub downloads.
  systemd.user.services.flatpak-managed-install.Unit.X-SwitchMethod = "keep-old";
  home.activation.flatpak-managed-install = lib.mkForce (
    lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
      $DRY_RUN_CMD ${config.systemd.user.systemctlPath} is-system-running -q && \
        ${config.systemd.user.systemctlPath} --user start --no-block flatpak-managed-install.service || true
    ''
  );

  services.flatpak.packages = [
    "com.dingtalk.DingTalk"
    "org.gtk.Gtk3theme.adw-gtk3-dark"
  ];

  # Apply to every Flatpak app. host + session/system bus + all devices is
  # equivalent to a normal install for files, D-Bus, and hardware access.
  services.flatpak.overrides.global = {
    Context = {
      # host includes home, exposes host-os/host-etc under /run/host, and leaves
      # /tmp to Flatpak so socket permissions can mount the X11 socket there.
      filesystems = [
        "host"
        "xdg-config/gtk-3.0:ro"
      ];
      sockets = [
        "wayland"
        "x11"
        # Do not add fallback-x11. Combined with wayland, Flatpak treats X11 as
        # fallback-only and unsets DISPLAY even when x11 is also listed.
        "pulseaudio"
        "session-bus"
        "system-bus"
        "ssh-auth"
        "pcsc"
        "cups"
      ];
      devices = [ "all" ];
      shared = [ "network" "ipc" ];
      features = [ "devel" "multiarch" "bluetooth" ];
    };

    Environment = {
      FONTCONFIG_FILE = "${config.xdg.configHome}/fontconfig/flatpak-cjk.conf";
      XCURSOR_THEME = config.home.pointerCursor.name;
      XCURSOR_SIZE = toString config.home.pointerCursor.size;
      XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";
      QT_QPA_SYSTEM_ICON_THEME = config.gtk.iconTheme.name;
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
    };
  };

  # Flathub preloads libdingtalk_wayland_screenshare.so whenever
  # WAYLAND_DISPLAY is set or XDG_SESSION_TYPE=wayland. That hook intercepts
  # XGetImage (file-dialog thumbnails, open file) and abort()s on a portal
  # handshake panic. DingTalk is X11-only; keep the Wayland socket off this
  # app so the hook never loads. This is not a DISPLAY/QT_QPA_PLATFORM override.
  services.flatpak.overrides."com.dingtalk.DingTalk" = {
    Context.sockets = [ "!wayland" ];
    Environment = {
      XDG_SESSION_TYPE = "x11";
      # Preserve fractional X11 DPI values reported by xwayland-satellite while
      # adapting automatically to 1x and differently scaled displays.
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_SCALE_FACTOR_ROUNDING_POLICY = "PassThrough";
    };
  };
}
