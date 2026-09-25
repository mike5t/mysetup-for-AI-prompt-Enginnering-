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
    # Pinned snapshot of Anthropic's public agent skills. Linked read-only into
    # ~/.pi/agent/skills so a fresh machine gets the same skill set without a
    # manual clone. See home.nix and README.md.
    anthropics-skills = {
      url = "github:anthropics/skills/9d2f1ae187231d8199c64b5b762e1bdf2244733d";
      flake = false;
    };
  };

  outputs = { nixpkgs, home-manager, firstmate, anthropics-skills, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."miket5" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit firstmate;
          anthropicsSkills = anthropics-skills;
        };
        modules = [ ./home.nix ];
      };
    };
}
