{
  description = "Linux Agentic Dev Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdr = {
      url = "github:herdrdev/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Firstmate is an agent distro/repository rather than a CLI package.
    firstmate = {
      url = "github:kunchenguid/firstmate";
      flake = false;
    };
  };

  outputs = { nixpkgs, home-manager, herdr, firstmate, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."miket5" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit herdr firstmate; };
        modules = [ ./home.nix ];
      };
    };
}
