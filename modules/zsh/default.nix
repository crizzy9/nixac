{ config, pkgs, lib, ... }:
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

      # Nix home-manager (nixac)
      hs = "home-manager switch --flake ~/nixac";
      hb = "home-manager build --flake ~/nixac";
      update = "nix flake update --flake ~/nixac && home-manager switch --flake ~/nixac";
      generations = "home-manager generations";
      flake-check = "nix flake check ~/nixac";
      nspnew = "nix-shell -p";
      asr = "atuin scripts run";

      # Git
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

      # Clipboard (macOS native)
      jj = "pbpaste | jq . | pbcopy";
      jjn = "pbpaste | jq . | nvim - +'set syntax=json'";
      jjj = "pbpaste | jq .";
    };

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";

    initContent =
      ''
        # Homebrew PATH — keep brew separate from nix
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

        # Transient prompt config
        TRANSIENT_PROMPT_PROMPT='$(starship prompt --terminal-width="$COLUMNS" --keymap="''${KEYMAP:-}" --status="$STARSHIP_CMD_STATUS" --pipestatus="''${STARSHIP_PIPE_STATUS[*]}" --cmd-duration="''${STARSHIP_DURATION:-}" --jobs="$STARSHIP_JOBS_COUNT")'
        TRANSIENT_PROMPT_TRANSIENT_PROMPT='$(starship module character)'
      '';
  };

  # Homebrew PATH in session (for non-interactive tools)
  home.sessionPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "$HOME/.local/bin"
  ];

  # direnv + nix-direnv — enables devenv / direnv workflows
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

  programs.starship.enableZshIntegration = true;
  programs.atuin.enableZshIntegration = true;
}
