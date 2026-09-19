{ pkgs, ... }:

let
  notoCjkSans = pkgs.noto-fonts-cjk-sans.override { static = true; };
in
{
  # Make fonts from home.packages visible to desktop applications.
  fonts.fontconfig.enable = true;

  fonts.fontconfig.defaultFonts = {
    sansSerif = [
      "Noto Sans"
      "Noto Sans CJK SC"
    ];
    serif = [
      "Noto Serif"
      "Noto Serif CJK SC"
    ];
    monospace = [
      "Noto Sans Mono"
      "Noto Sans Mono CJK SC"
    ];
    emoji = [ "Noto Color Emoji" ];
  };

  home.packages = with pkgs; [
    nerd-fonts.intone-mono
    noto-fonts
    notoCjkSans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    noto-fonts-monochrome-emoji
    wqy_zenhei
  ];

  # WeChat requests the family name "Noto Sans SC" while nixpkgs exposes
  # the same CJK family as "Noto Sans CJK SC".
  #
  # Flatpak runs `<reset-dirs/>` and only scans ~/.local/share/fonts plus
  # /run/host/fonts. Nix profile fonts disappear, Fedora CJK VF wins, and
  # Qt5 (DingTalk) renders Chinese as tofu. Reject the VF by both host and
  # sandbox paths, and publish static CJK into the XDG fonts dir.
  xdg.configFile."fontconfig/conf.d/80-noto-sans-sc.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <selectfont>
        <rejectfont>
          <glob>*NotoSansCJK-VF*</glob>
          <glob>*NotoSerifCJK-VF*</glob>
          <glob>*NotoSansMonoCJK-VF*</glob>
        </rejectfont>
      </selectfont>

      <alias binding="same">
        <family>Noto Sans SC</family>
        <accept><family>Noto Sans CJK SC</family></accept>
      </alias>
    </fontconfig>
  '';

  xdg.dataFile."fonts/nix-cjk-sans".source = "${notoCjkSans}/share/fonts/opentype/noto-cjk";
  xdg.dataFile."fonts/wqy-zenhei.ttc".source = "${pkgs.wqy_zenhei}/share/fonts/truetype/wqy-zenhei.ttc";

  # Flatpak sets XDG_CONFIG_HOME to ~/.var/app/<id>/config, so conf.d under
  # ~/.config/fontconfig is ignored. Point FONTCONFIG_FILE at an absolute path
  # that includes the runtime config then rejects CJK VF.
  xdg.configFile."fontconfig/flatpak-cjk.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
      <selectfont>
        <rejectfont>
          <glob>*NotoSansCJK-VF*</glob>
          <glob>*NotoSerifCJK-VF*</glob>
          <glob>*NotoSansMonoCJK-VF*</glob>
        </rejectfont>
      </selectfont>
    </fontconfig>
  '';
}
