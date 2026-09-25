# Fonts, home-manager side.
#
# When nix-darwin is driving (darwinManaged = true) darwin/fonts.nix already
# installed JetBrains Mono Nerd Font system-wide into /Library/Fonts/Nix Fonts,
# so this module does nothing.
#
# In the home-manager-only fallback there is no such option — home-manager has
# no darwin font target — so link the same package into ~/Library/Fonts/nixac,
# which macOS scans without any privileges.
{
  pkgs,
  lib,
  darwinManaged,
  ...
}:
let
  font = pkgs.nerd-fonts.jetbrains-mono;
in
lib.mkIf (!darwinManaged) {
  home.packages = [ font ];

  home.activation.linkFonts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/Library/Fonts/nixac"
    $DRY_RUN_CMD rm -rf "$target"
    $DRY_RUN_CMD mkdir -p "$target"
    for f in ${font}/share/fonts/truetype/NerdFonts/*/*.ttf; do
      [ -e "$f" ] || continue
      $DRY_RUN_CMD ln -sf "$f" "$target/"
    done
  '';
}
