{ lib, pkgs, ... }:

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
    Net/ThemeName "adw-gtk3-dark"
    Net/IconThemeName "Adwaita"
    Gtk/CursorThemeName "Adwaita"
    Gtk/CursorThemeSize 24
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

  # X11/XWayland apps resolve the cursor theme name "default" through here. The
  # host copy is a symlink into /etc/alternatives, which does not exist inside
  # the Flatpak sandbox.
  xdg.dataFile."icons/default/index.theme".text = ''
    [Icon Theme]
    Inherits=Adwaita
  '';

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
    # GTK3/GTK4 theme used by Noctalia's GTK templates.
    pkgs.adw-gtk3

    # Qt5 and Qt6 theme selectors for Noctalia-generated color schemes.
    pkgs.libsForQt5.qt5ct
    pkgs.qt6Packages.qt6ct

    # GTK theme selector and first-run cleanup tool.
    pkgs.nwg-look
  ];

  # Qt6 is the default for current applications. Qt5 applications can be
  # launched with QT_QPA_PLATFORMTHEME=qt5ct when needed.
  home.sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";
}
