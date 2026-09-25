# ─────────────────────────────────────────────────────────────────────────────
# Homebrew — declarative for the apps nixac cares about, NON-DESTRUCTIVE for
# everything else.
#
# THE IMPORTANT LINE IS `onActivation.cleanup = "none"`.
#
# komashi (lumino) uses cleanup = "zap", which uninstalls every formula and
# cask that isn't in the generated Brewfile on each activation. That is exactly
# what would wipe apps you install by hand. With "none", nix-darwin installs
# what's declared below and then leaves the rest of your Homebrew prefix alone,
# permanently. `brew install --cask whatever` survives every rebuild and never
# needs to be mirrored here.
#
# nix-darwin does NOT install Homebrew itself — scripts/bootstrap-darwin.sh does.
# ─────────────────────────────────────────────────────────────────────────────
{ lib, host, ... }:

lib.mkIf host.features.homebrew {
  homebrew = {
    enable = true;

    onActivation = {
      # none  → only ever add; never remove anything (what you asked for)
      # uninstall → remove Brewfile-absent packages but keep their data
      # zap   → remove packages AND their data  ← komashi's setting, NOT used here
      cleanup = "none";

      # Don't `brew update` or upgrade unrelated packages during a rebuild.
      # Keeps activation fast and stops nixac from bumping versions you pinned
      # by hand. Run `brew upgrade` yourself whenever you want.
      autoUpdate = false;
      upgrade = false;
    };

    # Homebrew ≥6 refuses formulae/casks from untrusted third-party taps, and
    # `brew bundle` rewrites the trust store from the Brewfile — a manual
    # `brew trust` gets wiped. Tap-level trusted = true is the only durable
    # form (unqualified brew/cask names can't carry trust themselves).
    taps = [
      {
        name = "nikitabobko/tap"; # aerospace
        trusted = true;
      }
      {
        name = "FelixKratz/formulae"; # borders
        trusted = true;
      }
      {
        name = "multica-ai/tap"; # multica
        trusted = true;
      }
    ];

    brews = [
      # Multica (multica.ai) — CLI + local daemon that registers this machine as
      # an agent runtime, so work assigned in Multica runs through the agent
      # CLIs installed here (claude, codex, …). The tap formula is the
      # project's only supported package (no cask, not in nixpkgs); the desktop
      # app is a separate .dmg from multica.ai/download if you want the GUI.
      # After the first switch:  multica login  →  multica daemon start
      "multica-ai/tap/multica"

      # JankyBorders — active-window border highlight for AeroSpace.
      # Launched by darwin/launchd.nix and by aerospace's after-startup-command.
    ]
    ++ lib.optional host.features.borders "borders";

    casks = [
      # ── Window management ──
      "aerospace"

      # ── Terminal ──
      "ghostty"

      # ── GUI apps ──
      "obsidian"
      "raycast"
      "spotify"
      "vorssaint"

      # ── Browsers ──
      # Firefox: intentionally NOT declared — you manage it yourself.
      # Zen: installed by Nix via the zen-browser flake (home/apps/zen.nix).
      #      To switch Zen to Homebrew instead, set features.zen = false in
      #      hosts/mosaic/default.nix and uncomment the next line.
      # "zen"
    ]
    ++ lib.optional host.features.karabiner "karabiner-elements";
  };
}
