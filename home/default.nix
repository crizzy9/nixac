# Home-manager layer. Shared verbatim by BOTH flake outputs:
#   darwinConfigurations.mosaic   (nix-darwin manages the system half)
#   homeConfigurations.spadia     (no sudo; this is all there is)
#
# Modules here must never assume nix-darwin is present. Where the two differ,
# branch on the `darwinManaged` specialArg rather than forking the module.
{
  pkgs,
  lib,
  host,
  ...
}:
{
  imports = [
    # Secrets first — modules that declare sops.secrets depend on its config.
    ./tools/sops.nix

    # ── Shell environment ──
    ./shell/zsh
    ./shell/nushell
    ./shell/neovim
    ./shell/tmux.nix
    ./shell/ghostty.nix

    # ── Core developer tools ──
    ./tools/starship.nix
    ./tools/atuin.nix
    ./tools/git.nix
    ./tools/gh.nix
    ./tools/lazygit.nix
    ./tools/yazi
    ./tools/television.nix
    ./tools/fonts.nix
    ./tools/onepassword.nix

    # ── Desktop / window management ──
    ./desktop/aerospace.nix
    ./desktop/karabiner

    # ── Apps ──
    ./apps/zen.nix

    # ── Not imported, kept for later ──────────────────────────────────────
    # ./apps/firefox.nix      — you manage Firefox outside Nix
    # ./agents/claude-code.nix — set features.agents = true and import
    # ./agents/agent-sync.nix
  ];

  home = {
    # mkDefault is required, not cosmetic: home-manager's nix-darwin
    # integration already sets both of these at normal priority from
    # users.users.<name>.{name,home}. A normal-priority definition here would
    # be a conflicting definition in the darwin output. As defaults they lose
    # to nix-darwin's, and still apply in the standalone home-manager output
    # where nothing else defines them.
    username = lib.mkDefault host.username;
    homeDirectory = lib.mkDefault host.homeDirectory;
    stateVersion = host.stateVersion;

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      # Consumed by the fnew/finit helpers in shell/zsh/utilities.zsh.
      DOTFILES = host.repoDir;
      # The sops CLI defaults to ~/Library/Application Support/sops on macOS,
      # which is NOT where the sops-nix module looks. Pin both to one path.
      SOPS_AGE_KEY_FILE = "${host.homeDirectory}/.config/sops/age/keys.txt";
    };

    # Core CLI tools available everywhere. Language servers and formatters
    # live in shell/neovim; anything project-scoped belongs in a devenv shell.
    packages = with pkgs; [
      # Search & navigation
      ripgrep
      fd
      fzf
      jq
      yq-go
      tree

      # Modern CLI replacements
      eza
      bat
      btop
      trash-cli
      fastfetch

      # Git tooling (delta, diffnav, worktrunk) comes from tools/gh.nix;
      # sesh comes from shell/tmux.nix.

      # Nix tooling
      nh
      nixfmt
      nix-tree
      nurl # used by the `pfg` nushell helper

      # Dev environments
      devenv
    ];
  };

  programs.home-manager.enable = true;

  xdg.enable = true;

  # macOS-only repo. Fail loudly rather than half-building on Linux.
  assertions = [
    {
      assertion = pkgs.stdenv.hostPlatform.isDarwin;
      message = "nixac targets macOS only — see lumino for the NixOS configuration.";
    }
  ];

  # Silence HM's news prompt on every switch.
  news.display = "silent";

  # Put Nix-installed .app bundles somewhere macOS will actually find them.
  #
  # linkApps (the default while home.stateVersion < 25.11) only SYMLINKS into
  # ~/Applications/Home Manager Apps, and Spotlight refuses to index symlinks
  # into /nix/store — so Zen installs correctly but is invisible to Spotlight,
  # Raycast and Launchpad. copyApps rsyncs real directories instead
  # (--copy-unsafe-links dereferences the store symlinks), which Spotlight
  # indexes normally. The two are mutually exclusive — home-manager asserts on
  # it — so linkApps has to be turned off explicitly.
  targets.darwin.linkApps.enable = false;
  targets.darwin.copyApps.enable = true;
}
