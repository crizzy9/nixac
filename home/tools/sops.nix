# SOPS secrets — decrypted at home-manager activation time. No sudo required.
#
# Dormant until you flip features.sops = true in hosts/mosaic/default.nix. Nothing here
# declares a secret on its own; consumers (tools/git.nix) declare their own
# under sops.secrets and are themselves gated on the same flag. See the README
# for the age-key + `sops secrets/secrets.yaml` bootstrap.
{ pkgs, host, ... }:
{
  sops = {
    age.keyFile = "${host.homeDirectory}/.config/sops/age/keys.txt";
    # Set unconditionally so dependent options always resolve. With
    # features.sops = false nothing declares a secret, so this is never read.
    defaultSopsFile = ../../secrets/secrets.yaml;
  };

  home.packages = with pkgs; [
    sops
    age
    ssh-to-age
  ];
}
