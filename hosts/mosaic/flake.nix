{
  description = "Mosaic devShells + local service stacks — every Mosaic repo's nix setup, kept out of the repos themselves";

  # ONE flake for all Mosaic checkouts, entered through ~/dev/mosaic/.envrc
  # (this directory's `envrc`, symlinked there by ./home.nix). The root nixac
  # flake.nix does not know about this one; it is entered only via the envrc.
  # Nothing here is ever committed to a Mosaic repo: the repos carry no
  # flake.nix, no flake.lock and no .envrc.
  #
  #   devShells.<system>."mosaic-<repo>"           what direnv loads in that repo
  #   packages.<system>."mosaic-<repo>-services"   the process-compose stack
  #                                                (postgres/redis/kafka/app…)
  #
  # Inside a repo's shell the stack is on PATH as `services`, so the old
  # `nix run .#services [-- -t]` is now `services [-t]`. Each stack keeps its
  # state in ./.data of the checkout it is started from, so two checkouts of
  # the same repo never share a database — same as before.
  #
  # One flake.lock for all five repos: they were already pinned to the same
  # nixpkgs/process-compose-flake/services-flake revisions, so this is the
  # same set of store paths evaluated once instead of five times.

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      imports = [
        inputs.process-compose-flake.flakeModule

        # One module per Mosaic repo. Each declares that repo's devShell and,
        # where the repo has local services, its process-compose stack.
        ./devShells/rails-api.nix
        ./devShells/api-server.nix
        ./devShells/ai-server.nix
        ./devShells/chat-bots.nix
        ./devShells/web.nix
      ];

      perSystem =
        {
          pkgs,
          lib,
          config,
          ...
        }:
        {
          formatter = pkgs.nixfmt;

          # `services` — a per-repo wrapper around that repo's process-compose
          # package, added to the repo's devShell. Shared here so the five
          # modules define it identically:  mosaicLib.servicesWrapper "<name>"
          #
          # It always runs from the checkout root: every dataDir in the stacks
          # is ./.data relative to the cwd, so starting from a subdirectory
          # would silently create a second, empty database there. For a git
          # worktree, --show-toplevel is the worktree's own root, which is the
          # point — two checkouts, two ./.data.
          _module.args.mosaicLib.servicesWrapper =
            name:
            pkgs.writeShellScriptBin "services" ''
              cd "$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 1
              exec ${config.process-compose.${name}.outputs.package}/bin/${name} "$@"
            '';
        };
    };
}
