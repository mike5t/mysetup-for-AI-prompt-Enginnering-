{
  description = "Linux Agentic Dev Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Herdr is managed by Homebrew only (Cellar 0.9.0); a second Nix build
    # previously shadowed it and caused client/server protocol skew.
    # Firstmate is an agent distro/repository rather than a CLI package.
    firstmate = {
      url = "github:kunchenguid/firstmate";
      flake = false;
    };
  };

  outputs = { nixpkgs, home-manager, firstmate, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."miket5" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit firstmate; };
        modules = [ ./home.nix ];
      };
    };
}
