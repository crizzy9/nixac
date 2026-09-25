# Ghostty — the only terminal in this config (kitty from komashi is not ported).
#
# The .app comes from the Homebrew cask; ghostty isn't in nixpkgs for
# aarch64-darwin. package = null tells Home Manager to skip installation but
# still manage ~/.config/ghostty/config and the zsh shell integration.
{ ... }:
{
  programs.ghostty = {
    enable = true;
    package = null;
    enableZshIntegration = true;

    settings = {
      theme = "catppuccin-mocha";
      font-family = "JetBrainsMono Nerd Font";
      font-size = 14;
      window-padding-balance = true;
      window-padding-x = 0;
      window-padding-y = 0;
      macos-titlebar-style = "hidden";
    };

    themes = {
      catppuccin-mocha = {
        background = "1e1e2e";
        foreground = "cdd6f4";
        cursor-color = "f5e0dc";
        selection-background = "353749";
        selection-foreground = "cdd6f4";
        palette = [
          "0=#45475a"
          "1=#f38ba8"
          "2=#a6e3a1"
          "3=#f9e2af"
          "4=#89b4fa"
          "5=#f5c2e7"
          "6=#94e2d5"
          "7=#bac2de"
          "8=#585b70"
          "9=#f38ba8"
          "10=#a6e3a1"
          "11=#f9e2af"
          "12=#89b4fa"
          "13=#f5c2e7"
          "14=#94e2d5"
          "15=#a6adc8"
        ];
      };
    };
  };
}
