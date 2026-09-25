# System / user launchd jobs that depend on Homebrew-installed binaries.
#
# These live at the nix-darwin layer (not home/) because their binaries come
# from Homebrew, which nix-darwin owns. In the home-manager-only output both
# are absent: AeroSpace still starts borders itself via its
# after-startup-command, and Karabiner's installer registers its own daemon.
{ lib, host, ... }:
{
  # ── Karabiner VirtualHIDDevice daemon ────────────────────────────────────
  # Karabiner-Elements is inert without this — it loads the DriverKit
  # extension. First launch also needs a manual Input Monitoring grant in
  # System Settings → Privacy & Security.
  launchd.daemons.karabiner-vhid-daemon = lib.mkIf host.features.karabiner {
    serviceConfig = {
      Label = "org.pqrs.Karabiner-DriverKit-VirtualHIDDevice.Daemon";
      ProgramArguments = [
        "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
      ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };

  # ── JankyBorders ─────────────────────────────────────────────────────────
  # Colours match the catppuccin-mocha palette used by ghostty/starship/tmux.
  launchd.user.agents.borders = lib.mkIf host.features.borders {
    serviceConfig = {
      Label = "com.felixkratz.borders";
      ProgramArguments = [
        "/opt/homebrew/bin/borders"
        "active_color=0xffe1e3e4"
        "inactive_color=0xff494d64"
        "width=5.0"
      ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
