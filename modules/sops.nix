# SOPS secrets management — decrypts secrets at home-manager activation time.
# No sudo required. Age key must exist at ~/.config/sops/age/keys.txt
{ config, lib, pkgs, ... }:
{
  # sops-nix home-manager module (imported in flake.nix)
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ../secrets/secrets.yaml;
  };

  home.packages = with pkgs; [
    sops
    age
    ssh-to-age
  ];
}
