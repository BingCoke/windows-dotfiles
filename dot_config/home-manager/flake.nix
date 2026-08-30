{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl = {
      url = "git+https://github.com/nix-community/nixGL.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nixgl, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      mkHome = { hostModule, desktop }:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          extraSpecialArgs = {
            inherit nixgl;
          };

          modules = [
            ./home.nix
            hostModule
          ] ++ (if desktop then [ ./modules/desktop.nix ] else [ ]);

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
