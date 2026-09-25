# ─────────────────────────────────────────────────────────────────────────────
# Host + user knobs for this machine.  THIS IS THE ONLY FILE YOU EDIT when you
# move to a new machine or a new employer.
#
# hosts/mosaic/ is everything specific to this host and job in one place:
#   default.nix          these knobs (imported by the root flake.nix)
#   home.nix             home-manager module: ~/dev/mosaic/.envrc, direnv whitelist, zsh hook
#   flake.nix            the Mosaic devShells + service stacks (a SEPARATE flake, own lock)
#   devShells/           one module per Mosaic repo: its devShell + process-compose stack
#   envrc                the one .envrc every Mosaic checkout loads through
#   direnv-siblings.zsh  the hook that makes direnv follow you between checkouts
#
# Everything under darwin/ and home/ reads from here, so a new host is a copy
# of this file plus a one-line change in flake.nix.
#
# Restrictive workplace?  Set features.* to false as needed and build the
# home-manager-only output:  home-manager switch --flake .#spadia
# ─────────────────────────────────────────────────────────────────────────────
{
  hostname = "mosaic";
  system = "aarch64-darwin";

  username = "spadia";
  homeDirectory = "/Users/spadia";

  # Absolute path to this repo on disk. Used for out-of-store symlinks — the
  # configs that a GUI app must be able to write back to (LazyVim lock files,
  # karabiner.json). Change if you clone somewhere other than ~/nixac.
  repoDir = "/Users/spadia/nixac";

  # Carried over from komashi — nix-darwin will set the system timezone to
  # this on every switch, so change it if this machine is somewhere else.
  timezone = "America/New_York";

  # home-manager stateVersion. Matches komashi — do not bump casually; it
  # selects migration defaults, not package versions.
  stateVersion = "24.11";
  # nix-darwin stateVersion (integer, separate from the HM one above).
  # 5 matches komashi. Current nix-darwin supports up to 7; bumping only
  # changes migration defaults, never package versions.
  darwinStateVersion = 5;

  # ── Git identity ───────────────────────────────────────────────────────────
  # `work` adds an includeIf that auto-switches identity (and SSH key) for
  # repos under any of work.dirs. Set work.enable = false at a job that
  # doesn't need a split.
  git = {
    userName = "crizzy9";
    userEmail = "shyampadia@live.com";
    work = {
      enable = true;
      # Keep the trailing slash.
      dirs = [ "~/dev/mosaic/" ];
      userName = "spadia";
      userEmail = "shyam@mosaicapp.com";
    };

    # SSH host aliases written to ~/.ssh/config. Each becomes a `Host <name>`
    # block pointing at github.com with a specific key and IdentitiesOnly.
    #
    # identityFile picks where the key comes from:
    #   "<path>"  — a plain key file you manage yourself
    #   null      — pull it from sops (needs features.sops = true and the
    #               matching entry in secrets/secrets.yaml)
    #
    # A work key is deliberately a plain file here: employers commonly forbid
    # company SSH keys living in a personal repo, even encrypted. Flip it to
    # null only if you have actually checked that's allowed.
    ssh = {
      personal = {
        identityFile = "/Users/spadia/.ssh/id_ed25519";
        sopsSecret = "git_ssh_key";
      };
      work = {
        identityFile = "/Users/spadia/.ssh/id_ed25519_mosaic";
        sopsSecret = "git_ssh_key_work";
      };
    };
  };

  # ── Feature toggles ────────────────────────────────────────────────────────
  # Flip these off rather than deleting modules — every module file stays in
  # the tree so a future job can turn it back on.
  features = {
    # Homebrew-installed GUI apps + formulae, declared in darwin/homebrew.nix.
    # Never destructive: onActivation.cleanup = "none" leaves your manual
    # `brew install`s untouched, forever.
    homebrew = true;

    # Zen browser via the 0xc000022070 flake (aarch64-darwin supported).
    # Set false and add "zen" to darwin/homebrew.nix casks to use brew instead.
    zen = true;
    # Tridactyl (vim keybindings in Zen) + its native messaging host.
    zenTridactyl = true;

    # AeroSpace tiling WM config. The app itself comes from Homebrew.
    aerospace = true;
    # Four-finger trackpad workspace swipes. Builds from source (~1 min) and
    # needs a manual Accessibility grant after every store-path change.
    aerospaceSwipe = true;
    # JankyBorders active-window highlight (brew formula + launchd agent).
    borders = true;
    # Karabiner-Elements config symlink + system VirtualHIDDevice daemon.
    karabiner = true;

    # Touch ID for sudo (nix-darwin output only).
    touchIdSudo = true;

    # sops-nix secret decryption. Stays dormant until you generate an age key
    # and populate secrets/secrets.yaml — see README.
    sops = false;

    # AI/agent tooling (claude-code, MCP servers, agent-sync). Modules live in
    # home/agents/ and are ready to import when you want them.
    agents = false;
  };
}
