# Atuin — SQLite-backed shell history. Ported wholesale from lumino's
# modules/shell/atuin.nix, with the Linux-only cwd_filter paths repointed at
# the macOS home directory.
{
  config,
  lib,
  host,
  ...
}:
let
  atuin = lib.getExe config.programs.atuin.package;
  zsh = lib.getExe config.programs.zsh.package;
in
{
  programs.atuin = {
    enable = true;
    daemon.enable = true;

    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      update_check = false;
      style = "compact";
      secrets_filter = true;

      # Matching commands are never stored, so they cannot be synced or used
      # as the automatic last-command context sent to Atuin AI.
      history_filter = [
        ''(?i)(^|\s)(export\s+)?(?:[A-Z_][A-Z0-9_]*(?:_KEY|_TOKEN|_SECRET|_PASSWORD|_PASSWD|_CREDENTIALS?|_AUTH)|API_?KEY|TOKEN|SECRET|PASSWORD|PASSWD|CREDENTIALS?)\s*=''
        ''(?i)(^|\s)--?(api[-_]?key|token|secret|password|passwd|client[-_]?secret|access[-_]?token)(=|\s+)''
        ''(?i)(authorization|proxy-authorization|x-api-key|x-auth-token)\s*:\s*\S+''
        ''(?i)[?&](api[-_]?key|token|secret|password|passwd)=[^&\s]+''
        ''(?i)\b[a-z][a-z0-9+.-]*://[^/\s:@]+:[^/\s@]+@''
        ''-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----''
        ''(?i)(^|[;&|]\s*)(sudo\s+)?(,\s+)?(sops|pass|gopass|bw\s+get|op\s+(read|item|get)|secret-tool\s+lookup|keepassxc-cli\s+show)(\s|$)''
        ''(?i)(\.config/sops-nix/secrets|/run/secrets)(/|\s|$)''
      ];

      # Never record history while sitting in a secrets directory.
      # Repointed from /home/nightwatcher to this machine's home.
      cwd_filter = [
        ''^${host.homeDirectory}/(\.config/sops-nix/secrets|\.password-store|\.ssh)(/|$)''
      ];

      daemon.sync_frequency = 300;

      ai = {
        enabled = true;
        yolo = false;
        opening = {
          send_last_command = true;
          send_cwd = false;
        };
        capabilities = {
          enable_history_search = true;
          enable_history_output = true;
          enable_file_tools = false;
          enable_command_execution = false;
        };
      };

      tmux = {
        enabled = true;
        width = "80%";
        height = "60%";
      };
    };
  };

  # Clear the stale `false` inherited from shells started before the tmux popup
  # was enabled, then start the proxy before Home Manager's `atuin init zsh`
  # hook. Atuin 18.18.1 prefers ZSH_ARGZERO even when it is only `zsh`, then
  # exports that value as SHELL — normalize it temporarily so --shell receives
  # the configured executable path rather than a bare command name.
  programs.zsh.initContent = lib.mkBefore ''
    export ATUIN_TMUX_POPUP=true
    _atuin_pty_proxy_original_argzero="$ZSH_ARGZERO"
    ZSH_ARGZERO="${zsh}"
    eval "$(${atuin} pty-proxy init zsh)"
    ZSH_ARGZERO="$_atuin_pty_proxy_original_argzero"
    unset _atuin_pty_proxy_original_argzero
  '';

  # Atuin owns Ctrl-R; keep fzf enabled without installing its history binding.
  programs.fzf.historyWidget.command = "";
}
