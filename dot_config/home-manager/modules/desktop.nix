{ config, lib, pkgs, ... }:

let
  codeMimeTypes = [
    "text/plain"
    "text/x-python"
    "application/x-shellscript"
    "application/x-fishscript"
    "text/x-csrc"
    "text/x-chdr"
    "text/x-c++src"
    "text/x-c++hdr"
    "text/rust"
    "text/x-go"
    "text/x-java"
    "text/javascript"
    "text/vnd.trolltech.linguist"
    "application/json"
    "application/toml"
    "application/yaml"
    "text/x-lua"
    "text/x-makefile"
    "application/x-ruby"
    "application/x-php"
    "text/css"
  ];

  xsettingsConfig = pkgs.writeText "xsettingsd.conf" ''
    Net/ThemeName "${config.gtk.gtk3.theme.name}"
    Net/IconThemeName "${config.gtk.gtk3.iconTheme.name}"
    Gtk/CursorThemeName "${config.home.pointerCursor.name}"
    Gtk/CursorThemeSize ${toString config.home.pointerCursor.size}
  '';

  thunar = pkgs.thunar.override {
    thunarPlugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  # nixos-unstable does not yet have nixpkgs 9e32df0.
  telaCircle = pkgs.tela-circle-icon-theme.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      find $out -xtype l -print -delete
    '';
  });

  gioModules = "${pkgs.gvfs}/lib/gio/modules";

  gpuSetup = pkgs.writeShellScriptBin "nix-gpu-setup" ''
    if [ "$(id -u)" -ne 0 ]; then
      exec /usr/bin/sudo -- ${lib.getExe config.targets.genericLinux.gpu.setupPackage} "$@"
    fi
    exec ${lib.getExe config.targets.genericLinux.gpu.setupPackage} "$@"
  '';
in
{
  imports = [
    ./compositors.nix
    ./wayland.nix
    ./input-method.nix
    ./fonts.nix
    ./flatpak.nix
  ];

  targets.genericLinux.enable = true;

  # The upstream activation message prints a store path. sudo does not search
  # the user profile, so the short command has to carry the absolute path.
  home.activation.checkExistingGpuDrivers = lib.mkForce (
    lib.hm.dag.entryAnywhere ''
      existing=$(readlink /run/opengl-driver || true)
      new=${config.targets.genericLinux.gpu.drivers}
      verboseEcho Existing drivers: ''${existing}
      verboseEcho New drivers: ''${new}
      if [[ -z "''${existing}" ]] ; then
        warnEcho "This non-NixOS system is not yet set up to use the GPU"
        warnEcho "with Nix packages. To set up GPU drivers, run"
        warnEcho "  nix-gpu-setup"
      elif [[ "''${existing}" != "''${new}" ]] ; then
        warnEcho "GPU drivers require an update, run"
        warnEcho "  nix-gpu-setup"
      fi
    ''
  );

  home.activation.hostSetupCommands = lib.hm.dag.entryAfter [ "installPackages" ] ''
    warnEcho "Host setup commands:"
    warnEcho "  nix-gpu-setup"
    warnEcho "  compositor-desktop install"
    warnEcho "  noctalia-host-auth check"
    warnEcho "  noctalia-host-auth install"
    warnEcho "  noctalia-host-auth test"
  '';

  gtk = {
    enable = true;
    theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3-dark";
    };
    iconTheme = {
      package = telaCircle;
      name = "Tela-circle-dark";
    };
    colorScheme = "dark";

    # Keep builtin dialogs client-decorated under xwayland-satellite.
    gtk3.extraConfig.gtk-dialogs-use-header = true;

    # Noctalia owns GTK4's generated CSS and colors.
    gtk4.theme = null;
  };

  home.pointerCursor = {
    enable = true;
    package = pkgs.catppuccin-cursors.mochaDark;
    name = "catppuccin-mocha-dark-cursors";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Flatpak includes this directory in its icon search path.
  xdg.dataFile."icons/${config.gtk.iconTheme.name}".source =
    "${config.gtk.iconTheme.package}/share/icons/${config.gtk.iconTheme.name}";

  systemd.user.services.xsettingsd = {
    Unit = {
      Description = "XSettings daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.xsettingsd}/bin/xsettingsd -c ${xsettingsConfig}";
      Restart = "on-failure";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.thunar = {
    Unit = {
      Description = "Thunar file manager";
      Documentation = [ "man:Thunar(1)" ];
    };

    Service = {
      Type = "dbus";
      ExecStart = "${thunar}/bin/thunar --daemon";
      BusName = "org.xfce.FileManager";
      KillMode = "process";
      Environment = [
        "GIO_EXTRA_MODULES=${gioModules}"
        "PATH=${config.home.profileDirectory}/bin:/usr/bin:/usr/sbin:/bin"
      ];
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.gvfs-daemon = {
    Unit = {
      Description = "Virtual filesystem service";
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.gvfs}/libexec/gvfsd";
      Type = "dbus";
      BusName = "org.gtk.vfs.Daemon";
      Slice = "session.slice";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.gvfs-udisks2-volume-monitor = {
    Unit = {
      Description = "Virtual filesystem service - disk device monitor";
      PartOf = [ "graphical-session.target" ];
      After = [ "gvfs-daemon.service" ];
    };

    Service = {
      ExecStart = "${pkgs.gvfs}/libexec/gvfs-udisks2-volume-monitor";
      Type = "dbus";
      BusName = "org.gtk.vfs.UDisks2VolumeMonitor";
      Slice = "session.slice";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  xdg.configFile."xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="thunar-volman" version="1.0">
      <property name="automount-media" type="empty">
        <property name="enabled" type="bool" value="true"/>
      </property>
      <property name="autobrowse" type="empty">
        <property name="enabled" type="bool" value="true"/>
      </property>
    </channel>
  '';

  xdg.configFile."Thunar/uca.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
    <action>
      <icon>utilities-terminal</icon>
      <name>在此打开终端</name>
      <submenu></submenu>
      <unique-id>1710000001-1</unique-id>
      <command>${pkgs.kitty}/bin/kitty --working-directory %f</command>
      <description>Open terminal in the selected folder</description>
      <range></range>
      <patterns>*</patterns>
      <startup-notify/>
      <directories/>
    </action>
    <action>
      <icon>utilities-terminal</icon>
      <name>在此打开终端</name>
      <submenu></submenu>
      <unique-id>1710000001-2</unique-id>
      <command>${pkgs.kitty}/bin/kitty --working-directory %d</command>
      <description>Open terminal in the file's folder</description>
      <range></range>
      <patterns>*</patterns>
      <startup-notify/>
      <other-files/>
      <text-files/>
      <image-files/>
      <audio-files/>
      <video-files/>
    </action>
    </actions>
  '';

  xdg.desktopEntries.kitty-nvim = {
    name = "Neovim (Kitty)";
    exec = "${pkgs.kitty}/bin/kitty ${pkgs.neovim}/bin/nvim %F";
    terminal = false;
    noDisplay = true;
    mimeType = codeMimeTypes;
  };

  home.activation.setMimeDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.xdg-utils}/bin/xdg-mime default thunar.desktop inode/directory
    ${lib.concatMapStringsSep "\n" (mimeType: "${pkgs.xdg-utils}/bin/xdg-mime default kitty-nvim.desktop ${mimeType}") codeMimeTypes}
  '';

  home.packages = [
    pkgs.xsettingsd
    thunar
    pkgs.gvfs
    pkgs.exfatprogs
    pkgs.samba
    pkgs.cifs-utils
    pkgs.xarchiver
    pkgs.xdg-user-dirs
    pkgs.clash-verge-rev
    pkgs.gearlever

    # Qt5 and Qt6 theme selectors for Noctalia-generated color schemes.
    pkgs.libsForQt5.qt5ct
    pkgs.qt6Packages.qt6ct
    gpuSetup
  ];

  # These resource selectors do not alter GTK or Qt palettes.
  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
    QT_QPA_SYSTEM_ICON_THEME = config.gtk.iconTheme.name;
    GIO_EXTRA_MODULES = gioModules;
  };

  systemd.user.sessionVariables = {
    QT_QPA_SYSTEM_ICON_THEME = config.gtk.iconTheme.name;
    XCURSOR_THEME = config.home.pointerCursor.name;
    XCURSOR_SIZE = toString config.home.pointerCursor.size;
    GIO_EXTRA_MODULES = gioModules;
  };
}
