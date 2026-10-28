{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";

    # not to download darwin deps
    agenix.inputs.darwin.follows = "";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      disko,
      agenix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations.daredevil = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          inherit pkgs-unstable;
        };
        modules = [
          disko.nixosModules.disko
          agenix.nixosModules.default
          # ./local-network.nix
          ./hetzner.nix
          ./configuration.nix
          ./hardware-configuration.nix
        ];

      };
    };
}
