# zsh — vi-mode, fzf-tab, transient prompt. Merged from lumino's
# modules/shell/zsh/ and the previous nixac config: lumino's Wayland clipboard
# aliases and Linux-only helpers are dropped, its rebuild aliases repointed at
# scripts/rebuild.sh in this repo.
{
  config,
  pkgs,
  host,
  ...
}:
let
  rebuild = "${host.repoDir}/scripts/rebuild.sh";
in
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    plugins = [
      {
        name = "zsh-vi-mode";
        src = "${pkgs.zsh-vi-mode}/share/zsh-vi-mode";
      }
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
    ];

    shellAliases = {
      ".." = "cd ..";
      la = "eza -la --icons auto --group-directories-first";
      lsag = "eza -lah --icons auto --git --group-directories-first";
      lsat = "eza -lah --icons auto --git --tree -L 2 --git-ignore";
      lg = "lazygit";
      v = "nvim";
      sv = "sudo nvim";
      rm = "trash";
      y = "yazi";

      # ── Nix rebuild — everything routes through scripts/rebuild.sh, which
      # picks darwin-rebuild or home-manager based on what's installed.
      rebuild = rebuild;
      hs = "${rebuild} switch";
      sync = "${rebuild} sync";
      update = "${rebuild} sync --update";
      dry-run = "${rebuild} dry";
      flake-check = "${rebuild} check";
      generations = "${rebuild} generations";
      rollback = "${rebuild} rollback";
      update-input = "nix flake update";
      nspnew = "nix-shell -p";
      nix-deps = "nix-tree";
      asr = "atuin scripts run";

      # ── Git
      gs = "git status --short";
      gd = "git diff";
      ga = "git add";
      gaa = "git add --all";
      gfa = "git fetch --all --tags --prune";
      gco = "git checkout";
      gcb = "git checkout -b";
      gcd = "git checkout -D";
      gcmsg = "git commit -m";
      gopull = "git pull origin \${git_current_branch}";
      gopush = "git push origin \${git_current_branch}";
      gprom = "git pull origin \${git_main_branch} --rebase --autostash";
      gprum = "git pull upstream \${git_main_branch} --rebase --autostash";
      glom = "git pull origin \${git_main_branch}";
      glum = "git pull upstream \${git_main_branch}";
      gluc = "git pull upstream \${git_current_branch}";
      glgg = "git log --graph --stat";
      glo = "git log --oneline --graph";

      # ── Clipboard (macOS native; lumino uses wl-copy/wl-paste here)
      jj = "pbpaste | jq . | pbcopy";
      jjn = "pbpaste | jq . | nvim - +'set syntax=json'";
      jjj = "pbpaste | jq .";
    };

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";

    initContent =
      ''
        # Homebrew and pipx-installed tools — must come before typeset -U path.
        # Nix and brew stay independent; this only makes brew binaries findable.
        path=(/opt/homebrew/bin /opt/homebrew/sbin $HOME/.local/bin $path)
      ''
      + ''
        ${builtins.concatStringsSep "\n" (
          map builtins.readFile [
            ./clipboard.zsh
            ./fzf-widgets.zsh
            ./git.zsh
            ./completions.zsh
            ./utilities.zsh
          ]
        )}

        source ${
          pkgs.fetchFromGitHub {
            owner = "olets";
            repo = "zsh-transient-prompt";
            rev = "bdff553570d8ef46f500daf41364bf5c06a11de5";
            hash = "sha256-+Tw9TFHtBMrx3JSHmohopZHWeLKUZWzng4NFHCJxLZk=";
          }
        }/transient-prompt.zsh-theme

        # Transient prompt — collapse past prompts to just the character.
        TRANSIENT_PROMPT_PROMPT='$(starship prompt --terminal-width="$COLUMNS" --keymap="''${KEYMAP:-}" --status="$STARSHIP_CMD_STATUS" --pipestatus="''${STARSHIP_PIPE_STATUS[*]}" --cmd-duration="''${STARSHIP_DURATION:-}" --jobs="$STARSHIP_JOBS_COUNT")'
        TRANSIENT_PROMPT_RPROMPT='$(starship prompt --right --terminal-width="$COLUMNS" --keymap="''${KEYMAP:-}" --status="$STARSHIP_CMD_STATUS" --pipestatus="''${STARSHIP_PIPE_STATUS[*]}" --cmd-duration="''${STARSHIP_DURATION:-}" --jobs="$STARSHIP_JOBS_COUNT")'
        TRANSIENT_PROMPT_TRANSIENT_PROMPT='$(starship module character)'
      '';
  };

  home.sessionPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "$HOME/.local/bin"
  ];

  # direnv + nix-direnv — per-project devenv / flake shells
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.yazi.enableZshIntegration = true;
  programs.starship.enableZshIntegration = true;
  programs.atuin.enableZshIntegration = true;
}
