{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak?ref=v0.7.0";
  };

  outputs = { nixpkgs, home-manager, nix-flatpak, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      mkHome = { hostModule, desktop }:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = [
            ./home.nix
            hostModule
          ] ++ (if desktop then [
            nix-flatpak.homeManagerModules.nix-flatpak
            ./modules/desktop.nix
          ] else [ ]);

        };
    in {
      homeConfigurations = {
        "kryond@iv-ufs" = mkHome {
          hostModule = ./hosts/iv-ufs.nix;
          desktop = true;
        };
        "bingcoke@home" = mkHome {
          hostModule = ./hosts/home.nix;
          desktop = true;
        };
        "kryond@iv-ufs-shell" = mkHome {
          hostModule = ./hosts/iv-ufs.nix;
          desktop = false;
        };
        "bingcoke@home-shell" = mkHome {
          hostModule = ./hosts/home.nix;
          desktop = false;
        };
      };
    };
}
