{ config, lib, pkgs, ... }:

let
  flatpakDataDir = "${config.xdg.dataHome}/flatpak/exports/share";

  # systemd environment.d files do not perform shell expansion. Keep the
  # concrete, host-specific directories supplied by targets.genericLinux and
  # omit entries such as `${NIX_STATE_DIR:-...}` that systemd cannot expand.
  systemdDataDirs = builtins.filter
    (directory: !(lib.hasInfix "$" directory))
    config.xdg.systemDirs.data;

  xdgDataDirs = lib.concatStringsSep ":" systemdDataDirs;
in
{
  home.packages = [ pkgs.flatpak ];

  xdg.systemDirs.data = [ flatpakDataDir ];

  systemd.user.sessionVariables.XDG_DATA_DIRS = lib.mkForce xdgDataDirs;

  # environment.d is only read when user@ starts. Linger keeps that manager
  # across compositor logout, so pin the same value on niri.service.
  home.file.".config/systemd/user/niri.service.d/10-flatpak-xdg-data-dirs.conf".text = ''
    [Service]
    Environment=XDG_DATA_DIRS=${xdgDataDirs}
  '';

  home.activation.importFlatpakXdgDataDirs = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
    ${config.systemd.user.systemctlPath} --user is-system-running -q && \
      $DRY_RUN_CMD ${config.systemd.user.systemctlPath} --user set-environment XDG_DATA_DIRS=${lib.escapeShellArg xdgDataDirs} || true
  '';

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
  ];

  # GTK searches XDG_DATA_HOME/themes before Flatpak's theme extensions.
  xdg.dataFile."themes/adw-gtk3".source =
    "${config.gtk.theme.package}/share/themes/adw-gtk3";
  xdg.dataFile."themes/adw-gtk3-dark".source =
    "${config.gtk.theme.package}/share/themes/adw-gtk3-dark";

  home.activation.maskFlatpakGtkThemes = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak mask --user \
      org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark
  '';

  # Apply to every Flatpak app. host + session/system bus + all devices is
  # equivalent to a normal install for files, D-Bus, and hardware access.
  services.flatpak.overrides.settings.global = {
    Context = {
      # host includes home, exposes host-os/host-etc under /run/host, and leaves
      # /tmp to Flatpak so socket permissions can mount the X11 socket there.
      filesystems = [
        "host"
        "xdg-config/gtk-3.0:ro"
        "xdg-config/gtk-4.0:ro"
        "xdg-data/themes:ro"
        # host already exposes these files, but Flatpak remaps XDG_*_HOME.
        # Client-side Fcitx panels look there, not at ~/.config or ~/.local.
        "xdg-config/fcitx5:ro"
        "xdg-data/fcitx5:ro"
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

  home.file.".local/share/applications/com.dingtalk.DingTalk.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=钉钉
    GenericName=dingtalk
    Comment=钉钉桌面版
    Exec=flatpak run --branch=stable --arch=x86_64 --command=dingtalk --file-forwarding com.dingtalk.DingTalk --ignore-certificate-errors @@u %U @@
    Icon=com.dingtalk.DingTalk
    Categories=Chat;Office;
    Keywords=dingtalk;
    MimeType=x-scheme-handler/dingtalk;x-scheme-handler/dingtalk_std_ind;
    X-Flatpak=com.dingtalk.DingTalk
  '';

  # Flathub preloads libdingtalk_wayland_screenshare.so whenever
  # WAYLAND_DISPLAY is set or XDG_SESSION_TYPE=wayland. That hook intercepts
  # XGetImage (file-dialog thumbnails, open file) and abort()s on a portal
  # handshake panic. DingTalk is X11-only; keep the Wayland socket off this
  # app so the hook never loads. This is not a DISPLAY/QT_QPA_PLATFORM override.
  services.flatpak.overrides.settings."com.dingtalk.DingTalk" = {
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
