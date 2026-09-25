# nix-darwin system layer. Everything here needs sudo and is skipped entirely
# by the home-manager-only output (homeConfigurations.spadia).
{ pkgs, host, ... }:
{
  imports = [
    ./nix-settings.nix
    ./homebrew.nix
    ./defaults.nix
    ./fonts.nix
    ./security.nix
    ./launchd.nix
  ];

  system.stateVersion = host.darwinStateVersion;

  nixpkgs.hostPlatform = host.system;
  nixpkgs.config.allowUnfree = true;

  # hostName only, matching komashi. networking.computerName is deliberately
  # NOT set — that is the user-visible name ("Shyam's MacBook Pro (2)") and
  # overwriting it is not something this port should do behind your back.
  networking.hostName = host.hostname;

  time.timeZone = host.timezone;

  # nix-darwin needs the user declared so home-manager knows where $HOME is.
  users.users.${host.username} = {
    name = host.username;
    home = host.homeDirectory;
  };

  # Required for any user-scoped system.defaults to apply.
  system.primaryUser = host.username;

  programs.zsh.enable = true;

  # System-wide CLI floor. Deliberately small — the real toolchain is
  # per-user in home/, so this only covers what root/system contexts and a
  # broken home-manager generation would need to recover.
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    home-manager
  ];
}
