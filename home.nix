{ config, pkgs, lib, ... }:

{
  imports = [
    # Secrets (must come before modules that use sops)
    ./modules/sops.nix

    # Shell environment
    ./modules/zsh
    ./modules/neovim
    ./modules/tmux.nix
    ./modules/ghostty.nix
    ./modules/git.nix
    ./modules/starship.nix
    ./modules/atuin.nix
    ./modules/lazygit.nix

    # CLI tools
    ./modules/yazi
    ./modules/gh.nix
    ./modules/nushell

    # Desktop & apps
    ./modules/aerospace.nix
    ./modules/firefox.nix

    # AI tools (disabled by default — set enable = true in each module)
    ./modules/claude-code.nix
    ./modules/agent-sync.nix
  ];

  home = {
    username = "spadia";
    homeDirectory = "/Users/spadia";
    stateVersion = "24.11";

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    # Core CLI tools available everywhere
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

      # Nix tooling
      nh
      nixfmt-rfc-style

      # Dev environment
      devenv
    ];
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # XDG directories
  xdg.enable = true;
}
