# AeroSpace tiling window manager for macOS.
# App comes from the Homebrew cask; this manages ~/.aerospace.toml.
#
# Bindings and window rules are transferred VERBATIM from komashi
# (lumino modules/desktop/aerospace.nix) — edit freely, nothing here has been
# retuned for this machine yet.
{
  config,
  pkgs,
  lib,
  host,
  ...
}:
let
  # Trackpad gestures — built from source (see aerospace-swipe.nix for why)
  aerospace-swipe = pkgs.callPackage ./aerospace-swipe.nix { };
in
lib.mkIf host.features.aerospace {
  home.file.".aerospace.toml".text = ''
    # ── Startup ────────────────────────────────────────────────────────
    after-login-command = []
    after-startup-command = [${
      if host.features.borders then
        "'exec-and-forget borders active_color=0xffe1e3e4 inactive_color=0xff494d64 width=5.0'"
      else
        ""
    }]
    start-at-login = true

    # ── Layout ─────────────────────────────────────────────────────────
    enable-normalization-flatten-containers = true
    enable-normalization-opposite-orientation-for-nested-containers = true
    accordion-padding = 30
    default-root-container-layout = 'tiles'
    default-root-container-orientation = 'auto'
    key-mapping.preset = 'qwerty'

    # ── Mouse follows focus ────────────────────────────────────────────
    on-focused-monitor-changed = ['move-mouse monitor-lazy-center']
    on-focus-changed = "move-mouse window-lazy-center"

    # ── Gaps ───────────────────────────────────────────────────────────
    [gaps]
    inner.horizontal = 10
    inner.vertical = 10
    outer.left = 10
    outer.bottom = 10
    outer.top = 10
    outer.right = 10

    # ── Main bindings ──────────────────────────────────────────────────
    [mode.main.binding]

    # Layout
    alt-slash = 'layout tiles horizontal vertical'
    alt-comma = 'layout accordion horizontal vertical'

    # Focus (vim-style, wraps across monitors)
    alt-h = [
      'focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors left',
      'move-mouse window-force-center',
    ]
    alt-j = [
      'focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors down',
      'move-mouse window-force-center',
    ]
    alt-k = [
      'focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors up',
      'move-mouse window-force-center',
    ]
    alt-l = [
      'focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors right',
      'move-mouse window-force-center',
    ]

    # Move windows
    alt-shift-h = 'move left'
    alt-shift-j = 'move down'
    alt-shift-k = 'move up'
    alt-shift-l = 'move right'

    # Resize
    alt-shift-minus = 'resize smart -50'
    alt-shift-equal = 'resize smart +50'

    # ── Workspaces (digits) ────────────────────────────────────────────
    # alt-1..5 reserved for tmux window switching (M-1..5)
    alt-6 = 'workspace 6'
    alt-7 = 'workspace 7'
    alt-8 = 'workspace 8'
    alt-9 = 'workspace 9'

    # ── Workspaces (alpha — app-specific) ──────────────────────────────
    alt-a = 'workspace A'
    alt-b = 'workspace B'
    alt-c = 'workspace C'
    alt-d = 'workspace D'
    alt-e = 'workspace E'
    alt-g = 'workspace G'
    alt-i = 'workspace I'
    alt-m = 'workspace M'
    alt-n = 'workspace N'
    alt-o = 'workspace O'
    alt-p = 'workspace P'
    alt-q = 'workspace Q'
    alt-r = 'workspace R'
    alt-s = 'workspace S'
    alt-t = 'workspace T'
    alt-u = 'workspace U'
    alt-v = 'workspace V'
    alt-w = 'workspace W'
    alt-x = 'workspace X'
    alt-y = 'workspace Y'
    alt-z = 'workspace Z'

    # ── Move node to workspace (+ follow) ──────────────────────────────
    # alt-shift-1..5 reserved for tmux window switching
    alt-shift-6 = ['move-node-to-workspace 6', 'workspace 6']
    alt-shift-7 = ['move-node-to-workspace 7', 'workspace 7']
    alt-shift-8 = ['move-node-to-workspace 8', 'workspace 8']
    alt-shift-9 = ['move-node-to-workspace 9', 'workspace 9']
    alt-shift-a = ['move-node-to-workspace A', 'workspace A']
    alt-shift-b = ['move-node-to-workspace B', 'workspace B']
    alt-shift-c = ['move-node-to-workspace C', 'workspace C']
    alt-shift-d = ['move-node-to-workspace D', 'workspace D']
    alt-shift-e = ['move-node-to-workspace E', 'workspace E']
    alt-shift-g = ['move-node-to-workspace G', 'workspace G']
    alt-shift-i = ['move-node-to-workspace I', 'workspace I']
    alt-shift-m = ['move-node-to-workspace M', 'workspace M']
    alt-shift-n = ['move-node-to-workspace N', 'workspace N']
    alt-shift-o = ['move-node-to-workspace O', 'workspace O']
    alt-shift-p = ['move-node-to-workspace P', 'workspace P']
    alt-shift-q = ['move-node-to-workspace Q', 'workspace Q']
    alt-shift-r = ['move-node-to-workspace R', 'workspace R']
    alt-shift-s = ['move-node-to-workspace S', 'workspace S']
    alt-shift-t = ['move-node-to-workspace T', 'workspace T']
    alt-shift-u = ['move-node-to-workspace U', 'workspace U']
    alt-shift-v = ['move-node-to-workspace V', 'workspace V']
    alt-shift-w = ['move-node-to-workspace W', 'workspace W']
    alt-shift-x = ['move-node-to-workspace X', 'workspace X']
    alt-shift-y = ['move-node-to-workspace Y', 'workspace Y']
    alt-shift-z = ['move-node-to-workspace Z', 'workspace Z']

    # Fullscreen
    alt-shift-f = 'fullscreen'

    # Workspace back-and-forth
    alt-tab = 'workspace-back-and-forth'

    # Monitor focus / move
    alt-right = 'focus-monitor --wrap-around next'
    alt-left = 'focus-monitor --wrap-around prev'
    alt-shift-right = 'move-workspace-to-monitor --wrap-around next'
    alt-shift-left = 'move-workspace-to-monitor --wrap-around prev'

    # Cycle workspaces on current monitor
    alt-shift-rightSquareBracket = 'move-node-to-workspace next'
    alt-shift-leftSquareBracket = 'move-node-to-workspace prev'
    # Cycle NON-EMPTY workspaces only: --stdin restricts cycling to the piped
    # list (workspaces with windows on the focused monitor), wrapping at ends
    alt-rightSquareBracket = 'exec-and-forget aerospace list-workspaces --monitor focused --empty no | aerospace workspace next --stdin --wrap-around'
    alt-leftSquareBracket = 'exec-and-forget aerospace list-workspaces --monitor focused --empty no | aerospace workspace prev --stdin --wrap-around'

    # Service mode
    alt-shift-semicolon = 'mode service'

    # ── Service mode ───────────────────────────────────────────────────
    [mode.service.binding]
    esc = ['reload-config', 'mode main']
    r = ['flatten-workspace-tree', 'mode main']
    f = ['layout floating tiling', 'mode main']
    backspace = ['close-all-windows-but-current', 'mode main']

    alt-shift-h = ['join-with left', 'mode main']
    alt-shift-j = ['join-with down', 'mode main']
    alt-shift-k = ['join-with up', 'mode main']
    alt-shift-l = ['join-with right', 'mode main']

    # ── Window rules — auto-assign apps to workspaces ──────────────────
    # T : Terminal, B : Browser, I : IDE, O : Obsidian, Z : Zoom
    # M : Messaging, P : Postman, C : Calendar/Outlook, N : Cursor, S : Spotify
    # Use `aerospace list-apps` to discover app IDs

    # ── Window rules — auto-assign apps to workspaces ──────────────────
    [[on-window-detected]]
    if.app-id = 'com.mitchellh.ghostty'
    run = 'move-node-to-workspace T'

    [[on-window-detected]]
    if.app-id = 'org.mozilla.firefox'
    run = 'move-node-to-workspace B'

    [[on-window-detected]]
    if.app-id = 'app.zen-browser.zen'
    run = 'move-node-to-workspace B'

    [[on-window-detected]]
    if.app-id = 'notion.id'
    run = 'move-node-to-workspace N'

    [[on-window-detected]]
    if.app-id = 'com.anthropic.claudefordesktop'
    run = 'move-node-to-workspace C'

    [[on-window-detected]]
    if.app-id = 'com.jetbrains.intellij'
    run = 'move-node-to-workspace I'

    [[on-window-detected]]
    if.app-id = 'md.obsidian'
    run = 'move-node-to-workspace O'

    [[on-window-detected]]
    if.app-id = 'us.zoom.xos'
    run = 'move-node-to-workspace Z'

    [[on-window-detected]]
    if.app-id = 'com.tinyspeck.slackmacgap'
    run = 'move-node-to-workspace M'

    [[on-window-detected]]
    if.app-id = 'com.postmanlabs.mac'
    run = 'move-node-to-workspace P'

    [[on-window-detected]]
    if.app-id = 'com.openai.codex'
    run = 'move-node-to-workspace C'

    [[on-window-detected]]
    if.app-id = 'com.microsoft.Outlook'
    run = 'move-node-to-workspace C'

    [[on-window-detected]]
    if.app-name-regex-substring = 'Cursor'
    run = 'move-node-to-workspace N'

    [[on-window-detected]]
    if.app-id = 'com.spotify.client'
    run = 'move-node-to-workspace S'

    [[on-window-detected]]
    if.app-id = 'com.TickTick.task.mac'
    run = 'layout floating'
  '';

  # ── Trackpad gestures — aerospace-swipe ─────────────────────────────────
  # FOUR-finger swipes switch workspaces: three-finger motion is owned by
  # macOS three-finger drag (trackpad.TrackpadThreeFingerDrag in
  # darwin/defaults.nix) — the two are mutually exclusive.
  # natural_swipe matches macOS Spaces direction; skip_empty mirrors the
  # alt-[ / alt-] non-empty cycling above. The agent reads this at startup —
  # restart it after changes (launchctl kickstart).
  # NOTE: macOS ties Accessibility/Input Monitoring approval to the binary
  # path, so after an update changes the store path, re-grant the permission.
  # mkIf wraps the whole attrset, not the individual entry: gating the value of
  # an attrsOf-submodule attribute leaves the key defined with no definitions,
  # which either errors out or (for launchd.agents) yields an enabled agent
  # with an empty config.
  xdg.configFile = lib.mkIf host.features.aerospaceSwipe {
    "aerospace-swipe/config.json".text = builtins.toJSON {
      haptic = false;
      natural_swipe = true;
      wrap_around = true;
      skip_empty = true;
      fingers = 4;
    };
  };

  launchd.agents = lib.mkIf host.features.aerospaceSwipe {
    aerospace-swipe = {
      enable = true;
      config = {
        ProgramArguments = [ "${aerospace-swipe}/bin/aerospace-swipe" ];
        RunAtLoad = true;
        KeepAlive = true;
        # Without these the agent's output goes nowhere and a permission
        # failure is completely silent — it keeps running, it just never sees
        # a gesture. Check these files first when swipes stop working.
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/aerospace-swipe.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/aerospace-swipe.log";
      };
    };
  };
}
