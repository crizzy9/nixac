# Nushell — optional alternative shell (zsh stays the login shell).
# Aliases mirror shell/zsh/default.nix; rebuild commands route through
# scripts/rebuild.sh so both shells behave identically.
{ config, pkgs, host, ... }:
let
  rebuild = "${host.repoDir}/scripts/rebuild.sh";
in
{
  programs.nushell = {
    enable = true;

    shellAliases = {
      # Basic navigation
      ".." = "cd ..";

      # Editor shortcuts
      v = "nvim";
      sv = "sudo nvim";
      vimdiff = "nvim -d";

      # File management
      y = "yazi";
      lg = "lazygit";

      # Atuin
      asr = "atuin scripts run";

      # Nix rebuild — routed through scripts/rebuild.sh
      rebuild = rebuild;
      hs = "${rebuild} switch";
      sync = "${rebuild} sync";
      update = "${rebuild} sync --update";
      "dry-run" = "${rebuild} dry";
      "flake-check" = "${rebuild} check";
      generations = "${rebuild} generations";
      rollback = "${rebuild} rollback";
      "update-input" = "nix flake update";
      nsp = "nix-shell -p";

      # Git shortcuts
      gs = "git status --short";
      gd = "git diff";
      ga = "git add";
      gaa = "git add --all";
      gfa = "git fetch --all --tags --prune";
      gco = "git checkout";
      gcb = "git checkout -b";
      gcd = "git checkout -D";
      gcmsg = "git commit -m";
      glgg = "git log --graph --stat";
      glo = "git log --oneline --graph";
    };

    extraConfig = builtins.readFile ./config.nu;

    # Environment variables
    environmentVariables = { CARAPACE_BRIDGES = "zsh,bash,inshellisense"; };
  };

  # Enable integrations
  programs.direnv = {
    enable = true;
    enableNushellIntegration = true;
    nix-direnv.enable = true;
  };

  programs.fzf.enable = true;

  programs.zoxide = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.yazi.enableNushellIntegration = true;

  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.atuin = {
    enable = true;
    enableNushellIntegration = true;
  };
}
