{
  description = "nixac — macOS developer environment (nix-darwin + home-manager)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Community Zen flake — gained first-class aarch64-darwin support, so this
    # is the same input lumino uses. homeModules.default == homeModules.beta.
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      sops-nix,
      ...
    }:
    let
      # hosts/mosaic/ holds everything for this machine: the knobs (default.nix),
      # the day-job devShells (flake.nix, its own lock) and the home module that
      # wires them in (home.nix).
      host = import ./hosts/mosaic;
      inherit (host) system;

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Home modules are IDENTICAL across both outputs. `darwinManaged` is the
      # only thing that differs: it tells a home module whether nix-darwin is
      # handling the system-level half (fonts, Homebrew, launchd daemons) or
      # whether it has to do that work itself.
      homeModulesFor = darwinManaged: {
        extraSpecialArgs = { inherit inputs host darwinManaged; };
        modules = [
          sops-nix.homeManagerModules.sops
          ./home
          # Host-specific home config stays out of ./home, which is host-agnostic.
          ./hosts/mosaic/home.nix
        ];
      };

      hmDarwin = homeModulesFor true;
      hmStandalone = homeModulesFor false;
    in
    {
      # ── Full system: nix-darwin + home-manager ───────────────────────────
      #   sudo darwin-rebuild switch --flake .#mosaic
      darwinConfigurations.${host.hostname} = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit inputs host; };
        modules = [
          ./darwin
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "bak";
              # Clobber a stale .bak instead of aborting activation when one
              # already exists. lumino sets this for the same reason; omitting
              # it is why the first re-switch failed on ~/.config/git/config.bak.
              # Single rolling backup, no accumulation.
              overwriteBackup = true;
              inherit (hmDarwin) extraSpecialArgs;
              users.${host.username}.imports = hmDarwin.modules;
            };
          }
        ];
      };

      # ── Fallback: home-manager only, zero sudo ───────────────────────────
      # For a locked-down machine where nix-darwin isn't an option. Same shell,
      # editor, terminal and window-manager config; Homebrew, Touch ID, fonts
      # and system defaults become manual (see README → Restrictive machines).
      #   home-manager switch --flake .#spadia
      homeConfigurations.${host.username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        inherit (hmStandalone) extraSpecialArgs modules;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          home-manager
          nixfmt
          sops
          age
          ssh-to-age
        ];
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
