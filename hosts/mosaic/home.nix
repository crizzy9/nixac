# Mosaic (day job): one direnv file for every checkout under ~/dev/mosaic, the
# devShells + local service stacks it loads (./flake.nix, a separate flake), and the
# zsh hook that makes direnv follow you between sibling checkouts.
#
# The point of the arrangement is that the Mosaic repos themselves carry NO
# flake.nix, flake.lock or .envrc — nothing nix-related can end up in a commit.
# See ./envrc for how a single parent .envrc tells the checkouts apart.
# Imported by the root flake.nix alongside ./home, not from home/default.nix.
{
  config,
  lib,
  host,
  ...
}:
let
  # Every directory that holds Mosaic checkouts gets the same .envrc.
  devDirs = [ "dev/mosaic" ];
  envrc = config.lib.file.mkOutOfStoreSymlink "${host.repoDir}/hosts/mosaic/envrc";
in
{
  # ~/dev/mosaic/.envrc → hosts/mosaic/envrc. Out-of-store symlink so an edit
  # to the envrc takes effect on the next cd without a rebuild — the same
  # pattern as karabiner.json and the LazyVim lock file.
  home.file = lib.genAttrs (map (d: "${d}/.envrc") devDirs) (_: {
    source = envrc;
  });

  # Trust it permanently; direnv otherwise demands `direnv allow` after every
  # edit. `exact`, not `prefix`, on purpose: a prefix whitelist would also
  # auto-trust any .envrc a Mosaic repo might one day commit, which is other
  # people's code.
  programs.direnv.config.whitelist.exact = map (d: "${host.homeDirectory}/${d}/.envrc") devDirs;

  programs.zsh.initContent = builtins.readFile ./direnv-siblings.zsh;
}
