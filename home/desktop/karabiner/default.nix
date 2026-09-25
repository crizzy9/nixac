# Karabiner-Elements keyboard customization.
#
# The app (Homebrew cask) and its VirtualHIDDevice daemon are set up at the
# nix-darwin layer — darwin/homebrew.nix and darwin/launchd.nix.
#
# Nix owns the symlink; Karabiner owns the mutable target. GUI edits write
# THROUGH the symlink into this repo's working tree, so changes stay
# git-tracked — commit or discard them here.
#
# One-time manual step per machine: grant Input Monitoring in
# System Settings → Privacy & Security when Karabiner first launches.
{
  config,
  lib,
  host,
  ...
}:
let
  karabinerConfigPath = "${host.repoDir}/home/desktop/karabiner/karabiner.json";
in
lib.mkIf host.features.karabiner {
  xdg.configFile."karabiner/karabiner.json".source =
    config.lib.file.mkOutOfStoreSymlink karabinerConfigPath;
}
