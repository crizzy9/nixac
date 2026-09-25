# Zen browser — Nix-managed via 0xc000022070/zen-browser-flake.
#
# On "is there a better macOS flake": no. That flake gained first-class
# aarch64-darwin support (its supportedSystems is linuxSystems ++
# ["aarch64-darwin"], with a macOS universal DMG source), so it IS the best
# option and keeps nixac in lockstep with lumino rather than diverging onto a
# second implementation. The alternatives — bandithedoge/nixpkgs-firefox-darwin
# and wuz/nix-darwin-browsers — are plain overlays with no home-manager module,
# so you'd lose declarative policies, profiles and extensions.
#
# The app lands in ~/Applications/Home Manager Apps/ (via
# targets.darwin.linkApps), which Spotlight and Raycast index.
#
# darwin.packageMode = "signed" (the module default, pinned explicitly below)
# installs the .app untouched so the upstream code signature survives — which
# is what keeps 1Password, iCloud Passwords, Touch ID and Gatekeeper working.
# It costs extraPrefs / extraPrefsFiles / pkcs11Modules / enableGnomeExtensions,
# none of which this config uses. Policies still apply: in signed mode they are
# written to the `app.zen-browser.zen` defaults domain instead of into the
# bundle. Switch to "wrapped" only if you ever need those four options.
#
# Policies ported from lumino's modules/apps/browsers/zen.nix. Firefox is NOT
# managed here — you handle that one yourself.
{
  inputs,
  pkgs,
  lib,
  host,
  ...
}:

{
  # `imports` can never sit inside mkIf — it is resolved before config exists.
  # Gating on host.features is fine here because `host` is a specialArg, not
  # part of config, so there is no recursion.
  imports = lib.optionals host.features.zen [ inputs.zen-browser.homeModules.default ];

  config = lib.mkIf host.features.zen {
    programs.zen-browser = {
      enable = true;

      darwin.packageMode = "signed";

      profiles."default" = {
        id = 0;
        isDefault = true;
      };

      # Tridactyl's native messaging host — needed for its :native commands.
      nativeMessagingHosts = lib.optionals host.features.zenTridactyl [ pkgs.tridactyl-native ];

      policies =
        let
          mkExtensionSettings = builtins.mapAttrs (
            _: pluginId: {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
              installation_mode = "force_installed";
            }
          );
          mkLockedAttrs = builtins.mapAttrs (
            _: value: {
              inherit value;
              status = "locked";
            }
          );
        in
        {
          ExtensionSettings = mkExtensionSettings (
            {
              # bitwarden removed from policy management upstream — it was
              # breaking the Zen UI. Install manually from AMO if you want it.
              "uBlock0@raymondhill.net" = "ublock-origin";
              "addon@darkreader.org" = "darkreader";
              "clipper@obsidian.md" = "web-clipper-obsidian";

              # 1Password. The GUID is the one 1Password's own native-messaging
              # manifest allows — see allowed_extensions in
              #   ~/Library/Application Support/Mozilla/NativeMessagingHosts/
              #   com.1password.1password.json
              # Zen reads that Mozilla directory (same as Firefox), and the
              # 1Password desktop app puts the manifest there itself, so the
              # native bridge needs no Nix wiring — only this extension plus
              # authorising Zen once in 1Password ▸ Settings ▸ Browser.
              "{d634138d-c276-4fc8-924b-40a0ea21d284}" = "1password-x-password-manager";
            }
            // lib.optionalAttrs host.features.zenTridactyl {
              "tridactyl.vim@cmcaine.co.uk" = "tridactyl";
            }
          );

          # NOTE: changing policies/preferences wipes tabs and settings and
          # creates a brand-new profile. Safe on a fresh machine like this one —
          # be careful once you have state you care about.
          Preferences = mkLockedAttrs {
            "media.getusermedia.screensharing.enabled" = true;
            # Native find-in-page on / and Ctrl+F (tridactyl's own find is unbound)
            "accessibility.typeaheadfind.manual" = true;
            # lumino also locks "geo.provider.use_geoclue" — Linux-only (needs
            # services.geoclue2), so it is deliberately absent here.
            "zen.folders.max-subfolders" = 25;
            "zen.folders.owned-tabs-in-folder" = true;
            "zen.folders.search-hover-delay" = 500;
            "zen.view.use-single-toolbar" = false;
            "browser.tabs.insertAfterCurrent" = true;
            "browser.tabs.warnOnClose" = true;
            "browser.ctrlTab.sortByRecentlyUsed" = true;
            "browser.engagement.ctrlTab.has-used" = true;
            "browser.startup.page" = 3;
            "services.sync.prefs.sync-seen.browser.tabs.warnOnClose" = true;
            "services.sync.prefs.sync-seen.browser.ctrlTab.sortByRecentlyUsed" = true;
            "zen.workspaces.continue-where-left-off" = true;
            # browser.uiCustomization.state intentionally NOT managed — see
            # lumino's .agents/memory/pattern_zen_pinned_popup_scale.md
          };

          AutofillAddressEnabled = false;
          AutofillCreditCardEnabled = false;

          # Get Zen's built-in password manager out of 1Password's way: no save
          # prompts (already set below via OfferToSaveLogins) and no about:logins
          # store competing for autofill. Drop this line if you ever want Zen's
          # own manager back.
          PasswordManagerEnabled = false;
          DisableAppUpdate = true;
          DisableFeedbackCommands = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableTelemetry = true;
          DontCheckDefaultBrowser = true;
          NoDefaultBookmarks = true;
          OfferToSaveLogins = false;
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
          Homepage.StartPage = "previous-session";
        };
    };
  };
}
