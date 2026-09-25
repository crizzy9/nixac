# Nix daemon settings. Ported from lumino's modules/core/nix-settings.nix,
# trimmed to the caches that actually serve aarch64-darwin (the hyprland and
# CUDA substituters only ever build Linux paths).
{ host, ... }:
{
  nix = {
    # Which Nix implementation the daemon runs. nix-darwin owns this, which is
    # why the *installer* choice barely matters: bootstrap installs official
    # Nix, and switching to Lix later is one declarative line plus a rebuild —
    # no reinstall, no uninstall.
    #   nix.package = pkgs.lix;
    # (Determinate is the exception — see the note on optimise below.)

    # Hard-links identical store paths. Cheap, and the Nix store on a dev
    # laptop is mostly duplicate closures.
    #
    # NOTE: this and everything else in this file requires nix.enable = true,
    # which is why scripts/bootstrap-darwin.sh installs OFFICIAL Nix rather
    # than Determinate.
    #
    # Determinate's distribution manages /etc/nix/nix.conf itself and requires
    # either `nix.enable = false` or its own module's `determinateNix.enable =
    # true`. Either way EVERY option in this file becomes dead code: settings
    # move to `determinateNix.customSettings` (a parallel option set writing
    # /etc/nix/nix.custom.conf), and nix.gc / nix.optimise / nix.linux-builder
    # / nix.package have no equivalent at all. That is the whole trade — not a
    # judgement on Determinate, which handles macOS-upgrade breakage better.
    optimise.automatic = true;

    # Automatic GC left off, matching komashi. Run it deliberately instead:
    #   nix-collect-garbage --delete-older-than 30d
    # gc = {
    #   automatic = true;
    #   interval = [ { Weekday = 7; Hour = 3; Minute = 15; } ];
    #   options = "--delete-older-than 30d";
    # };

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://nixpkgs.cachix.org"
        "https://cachix.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
        "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
      ];

      # Needed so `darwin-rebuild switch` can use the caches above without
      # re-authorising on every run.
      trusted-users = [
        "root"
        host.username
      ];

      max-substitution-jobs = 16;
      http-connections = 50;
    };
  };
}
