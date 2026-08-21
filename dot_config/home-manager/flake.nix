{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mangobar = {
      url = "github:mangowm/mangobar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl = {
      url = "git+https://github.com/nix-community/nixGL.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, mangobar, nixgl, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      mkHome = hostModule:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          extraSpecialArgs = {
            inherit mangobar nixgl;
          };

          modules = [
            ./home.nix
            hostModule
          ];
        };
    in {
      homeConfigurations = {
        "kryond@iv-ufs" = mkHome ./hosts/iv-ufs.nix;
        "bingcoke@home" = mkHome ./hosts/home.nix;
      };
    };
}
