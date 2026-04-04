# Firefox browser — installed via Homebrew on Darwin (package = null).
# Policies manage extensions, preferences, and security settings.
{ pkgs, ... }:
let
  mkExtensionSettings = builtins.mapAttrs (_: pluginId: {
    install_url =
      "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
    installation_mode = "force_installed";
  });
  locked = Value: { inherit Value; Status = "locked"; };
  lockedNum = Value: { inherit Value; Status = "locked"; Type = "number"; };
in {
  programs.firefox = {
    enable = true;
    package = null; # installed via brew
    policies = {
      ExtensionSettings = mkExtensionSettings {
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = "bitwarden-password-manager";
        "uBlock0@raymondhill.net" = "ublock-origin";
        "addon@darkreader.org" = "darkreader";
      };
      Preferences = {
        "browser.startup.page" = lockedNum 3; # restore previous session
        "browser.tabs.insertAfterCurrent" = locked true;
        "browser.tabs.warnOnClose" = locked true;
        "browser.ctrlTab.sortByRecentlyUsed" = locked true;
      };
      AutofillAddressEnabled = true;
      AutofillCreditCardEnabled = false;
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
    };
  };
}
