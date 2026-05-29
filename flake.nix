{
  description = "nixos time B)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    sops-nix.url = "github:Mic92/sops-nix";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, ... }:
    let
      vars = import ./vars.nix;
    in {
    nixosConfigurations.${vars.hostName} = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit vars; };
      modules = [
        ./configuration.nix
		  ./hardware-configuration.nix
		  ./packages.nix
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
        ];
      };
    };
}

