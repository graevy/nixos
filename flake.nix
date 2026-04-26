{
  description = "nixos time B)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
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
		  ./modules/xmrig.nix
        ];
      };
    };
}

