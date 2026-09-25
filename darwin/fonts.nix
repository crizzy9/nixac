# Fonts. Scoped to JetBrains Mono as requested.
#
# nix-darwin installs these into /Library/Fonts/Nix Fonts. The home-manager-only
# output can't write there, so home/tools/fonts.nix mirrors the same package
# into ~/Library/Fonts/nixac when darwinManaged == false.
{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    # Patched build — supplies the glyphs starship, ghostty, yazi, tmux and
    # LazyVim's icons all expect. Plain jetbrains-mono has no Nerd glyphs.
    nerd-fonts.jetbrains-mono
  ];
}
