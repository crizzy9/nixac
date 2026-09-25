# Touch ID for sudo.
#
# `sudo_local` is the Apple-sanctioned drop-in (/etc/pam.d/sudo_local) that
# survives macOS updates — unlike editing /etc/pam.d/sudo directly, which every
# major update reverts. `reattach` makes it work inside tmux, where the sudo
# process is detached from the GUI session and would otherwise fall back to a
# password prompt.
{ lib, host, ... }:

lib.mkIf host.features.touchIdSudo {
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };
}
