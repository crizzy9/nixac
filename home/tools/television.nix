# Television (tv) — the unified fuzzy-finder layer. Ported from lumino's
# modules/shell/television/, with its two NixOS-only channels (systemctl,
# nixos-rebuild) swapped for macOS equivalents and the flake path repointed
# from ~/lumino to this repo.
{
  config,
  host,
  ...
}:
{
  programs.television = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      ui = {
        use_nerd_font_icons = true;
        input_bar.position = "top";
      };
    };

    channels = {
      # Carried over unchanged from lumino.
      sesh = {
        metadata = {
          name = "sesh";
          description = "Browse and connect to tmux sessions via sesh";
        };
        source.command = "sesh list --icons";
        preview.command = "tmux capture-pane -t '{2..}' -ep 2>/dev/null || echo 'Session not running'";
      };

      flake-inputs = {
        metadata = {
          name = "flake-inputs";
          description = "Browse nixac flake inputs";
        };
        source.command = "nix flake metadata ${host.repoDir} --json 2>/dev/null | jq -r '.locks.nodes | keys[]' | grep -v root";
        preview.command = "nix flake metadata ${host.repoDir} --json 2>/dev/null | jq '.locks.nodes.\"{}\"'";
      };

      # ── macOS replacements for lumino's nixos-services / nixos-generations ──
      darwin-generations = {
        metadata = {
          name = "darwin-generations";
          description = "Browse nix-darwin system generations";
        };
        source.command = "darwin-rebuild --list-generations 2>/dev/null | tail -r";
        preview.command = "echo '{}'";
      };

      launchd-agents = {
        metadata = {
          name = "launchd-agents";
          description = "Browse loaded launchd user agents";
        };
        source.command = "launchctl list | tail -n +2 | awk '{print $3}'";
        preview.command = "launchctl list '{}' 2>/dev/null || echo 'No detail available'";
      };

      brew-casks = {
        metadata = {
          name = "brew-casks";
          description = "Browse installed Homebrew casks";
        };
        source.command = "brew list --cask 2>/dev/null";
        preview.command = "brew info --cask '{}' 2>/dev/null";
      };
    };
  };
}
