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

  gtk = {
    enable = true;
    theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3-dark";
    };
    iconTheme = {
      package = pkgs.tela-circle-icon-theme;
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
      ExecStart = "${pkgs.thunar}/bin/Thunar --daemon";
      BusName = "org.xfce.FileManager";
      KillMode = "process";
    };
  };

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
    pkgs.thunar
    pkgs.xdg-user-dirs
    pkgs.clash-verge-rev

    # Qt5 and Qt6 theme selectors for Noctalia-generated color schemes.
    pkgs.libsForQt5.qt5ct
    pkgs.qt6Packages.qt6ct
  ];

  # These resource selectors do not alter GTK or Qt palettes.
  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
    QT_QPA_SYSTEM_ICON_THEME = config.gtk.iconTheme.name;
  };

  systemd.user.sessionVariables = {
    QT_QPA_SYSTEM_ICON_THEME = config.gtk.iconTheme.name;
    XCURSOR_THEME = config.home.pointerCursor.name;
    XCURSOR_SIZE = toString config.home.pointerCursor.size;
  };
}
