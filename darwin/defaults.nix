# ─────────────────────────────────────────────────────────────────────────────
# macOS defaults — deliberately scoped to what AeroSpace actually needs.
#
# You asked to keep the rest in System Settings, so komashi's dock/finder/
# keyboard/appearance block is carried over COMMENTED OUT below rather than
# dropped. Uncomment any line to hand that setting back to Nix; a Nix-managed
# default overwrites whatever you set in the GUI on every rebuild, which is why
# they're off by default.
# ─────────────────────────────────────────────────────────────────────────────
{ ... }:
{
  system.defaults = {
    dock = {
      # AeroSpace guide §4.2 — Mission Control renders windows tiny because
      # AeroSpace stashes hidden windows in the bottom-right corner. Grouping
      # by application is the documented workaround.
      expose-group-apps = true;

      # "Automatically rearrange Spaces based on most recent use" fights
      # AeroSpace's fixed workspace→monitor assignment. Must stay off.
      mru-spaces = false;
    };

    trackpad = {
      # Three-finger drag and aerospace-swipe's gestures are mutually
      # exclusive — macOS owns three-finger motion when this is on. This is
      # precisely why home/desktop/aerospace.nix configures swipe with
      # fingers = 4. Managed here so the two can't drift out of sync.
      TrackpadThreeFingerDrag = true;

      # ...and this is the consequence nobody warns you about. Enabling
      # three-finger drag makes macOS move "swipe between full-screen
      # applications" onto FOUR fingers — the exact gesture aerospace-swipe
      # listens for. Left at the default (2) macOS switches Spaces underneath
      # you and AeroSpace appears to ignore the swipe entirely.
      #
      # 0 = off, 2 = swipe between full-screen applications.
      # AeroSpace does the workspace switching now, so macOS must not.
      TrackpadFourFingerHorizSwipeGesture = 0;
    };

    # ── Carried over from komashi, intentionally inactive ────────────────
    # dock = {
    #   autohide = true;
    #   autohide-delay = 0.0;
    #   autohide-time-modifier = 0.2;
    #   orientation = "bottom";
    #   tilesize = 48;
    #   show-recents = false;
    # };
    # finder = {
    #   AppleShowAllExtensions = true;
    #   AppleShowAllFiles = true;
    #   ShowPathbar = true;
    #   ShowStatusBar = true;
    #   FXPreferredViewStyle = "clmv";
    #   FXDefaultSearchScope = "SCcf";
    # };
    # NSGlobalDomain = {
    #   AppleShowAllExtensions = true;
    #   AppleInterfaceStyle = "Dark";
    #   KeyRepeat = 2;
    #   InitialKeyRepeat = 15;
    #   NSAutomaticCapitalizationEnabled = false;
    #   NSAutomaticSpellingCorrectionEnabled = false;
    # };
    # trackpad.Clicking = true;
  };
}
