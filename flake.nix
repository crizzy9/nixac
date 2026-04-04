{
  description = "Minimal Darwin home-manager config — no sudo required";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, sops-nix, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      # Usage: home-manager switch --flake .
      homeConfigurations."spadia" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          sops-nix.homeManagerModules.sops
          ./home.nix
        ];
      };

      # Quick dev shell with home-manager available
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.home-manager ];
      };
    };
}
