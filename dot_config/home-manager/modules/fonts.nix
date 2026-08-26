{ pkgs, ... }:

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
    noto-fonts
    (noto-fonts-cjk-sans.override { static = true; })
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    noto-fonts-monochrome-emoji
    wqy_zenhei
  ];

  # WeChat requests the family name "Noto Sans SC" while nixpkgs exposes
  # the same CJK family as "Noto Sans CJK SC".
  xdg.configFile."fontconfig/conf.d/80-noto-sans-sc.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <selectfont>
        <rejectfont>
          <glob>/usr/share/fonts/google-noto-sans-cjk-vf-fonts/NotoSansCJK-VF.ttc</glob>
        </rejectfont>
      </selectfont>

      <alias binding="same">
        <family>Noto Sans SC</family>
        <accept><family>Noto Sans CJK SC</family></accept>
      </alias>
    </fontconfig>
  '';
}
