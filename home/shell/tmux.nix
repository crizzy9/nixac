# tmux. Copied verbatim from lumino modules/shell/tmux.nix (prefix: C-Space).
{ pkgs, ... }:
let
  # NOTE: checkout for updated plugin configs https://haseebmajid.dev/posts/2023-07-10-setting-up-tmux-with-nix-home-manager/
  tmux-nerd-font-window-name = pkgs.tmuxPlugins.mkTmuxPlugin {
    name = "tmux-nerd-font-window-name";
    pluginName = "tmux-nerd-font-window-name";
    version = "2025-11-27";
    src = pkgs.fetchFromGitHub {
      owner = "crizzy9";
      repo = "tmux-nerd-font-window-name";
      rev = "0e56834";
      hash = "sha256-ElN592X3G7DQS6yAtO9OdGmM+h1ntwUfjST7CsIXfR0=";
    };
  };
in
{

  programs.tmux = {
    enable = true;
    mouse = true;
    keyMode = "vi";
    escapeTime = 0;
    baseIndex = 1;
    prefix = "C-Space";
    # shortcut."C-Space" = "";
    historyLimit = 500000;
    aggressiveResize = true;
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      yank
      tmux-fzf
      fzf-tmux-url
      # tmux-which-key
      # resurrect
    ];
    extraConfig = ''
      set-option -g default-terminal "screen-256color"
      set-option -sa terminal-overrides ",xterm*:Tc"

      set -g focus-events on
      set -g status-position top
      set -g set-clipboard on
      set -g detach-on-destroy off
      set -g extended-keys on
      set -g extended-keys-format csi-u

      set -g pane-base-index 1
      set-window-option -g pane-base-index 1
      set-option -g renumber-windows on
      set-option -g display-time 4000
      set-option -g status-interval 5
      set-option -g status-keys emacs

      bind -n M-h resize-pane -L 5
      bind -n M-l resize-pane -R 5
      bind -n M-k resize-pane -U 5
      bind -n M-j resize-pane -D 5

      bind -n M-` next-layout

      bind -n M-1 select-window -t :=1
      bind -n M-2 select-window -t :=2
      bind -n M-3 select-window -t :=3
      bind -n M-4 select-window -t :=4
      bind -n M-5 select-window -t :=5

      bind-key -n C-[ copy-mode
      unbind-key -T copy-mode-vi MouseDragEnd1Pane
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      bind-key -T prefix C-l send-keys -R C-l \; clear-history

      bind-key -T prefix C-Space switch-client -l
      bind-key -T prefix Space last-window

      bind-key x kill-pane

      bind-key -T prefix v split-window -v -c "#{pane_current_path}"
      bind-key -T prefix h split-window -h -c "#{pane_current_path}"

      bind-key -T prefix K display-popup -h 80% -w 80% -E "lazygit"

      bind-key -T prefix F display-popup -h 80% -w 80% -E "yazi"

      bind-key -n "C-g" run-shell "sesh connect \"$(
        sesh list --icons | fzf-tmux -p 55%,60% \
          --no-sort --ansi --border-label ' sesh ' --prompt '  ' \
          --header '  ^a all ^t tmux ^c configs ^x zoxide ^d tmux kill ^f find' \
          --bind 'tab:down,btab:up' \
          --bind 'ctrl-a:change-prompt(  )+reload(sesh list --icons)' \
          --bind 'ctrl-t:change-prompt(  )+reload(sesh list -t --icons)' \
          --bind 'ctrl-c:change-prompt(  )+reload(sesh list -c --icons)' \
          --bind 'ctrl-x:change-prompt(  )+reload(sesh list -z --icons)' \
          --bind 'ctrl-f:change-prompt(  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
          --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(  )+reload(sesh list --icons)'
      )\""

      # ── vim-tmux-navigator: pane-option detection, NOT ps ──────────────
      # The plugin's stock check is:
      #   ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '...(n?vim?)...'
      # That can never match here. Atuin's pty-proxy (tools/atuin.nix, needed
      # for the tmux Ctrl-R popup) owns the pane tty, so the pane's process
      # tree is atuin -> zsh -> nvim and `ps -t <pane_tty>` reports only
      # "atuin". No regex fixes that; the process genuinely is atuin.
      #
      # Instead neovim advertises itself by setting a pane-scoped tmux option
      # (see lazyvim/lua/plugins/vim-tmux-navigator.lua), and `if-shell -F`
      # tests it natively — no shell, no ps, no process-name guessing.
      #
      # These come after the plugin's run-shell in the generated config, so
      # they replace its root-table bindings.
      bind-key -n C-h if-shell -F '#{@pane-is-vim}' 'send-keys C-h' 'select-pane -L'
      bind-key -n C-j if-shell -F '#{@pane-is-vim}' 'send-keys C-j' 'select-pane -D'
      bind-key -n C-k if-shell -F '#{@pane-is-vim}' 'send-keys C-k' 'select-pane -U'
      bind-key -n C-l if-shell -F '#{@pane-is-vim}' 'send-keys C-l' 'select-pane -R'
      bind-key -n 'C-\' if-shell -F '#{@pane-is-vim}' 'send-keys C-\' 'select-pane -l'
      bind-key -T copy-mode-vi C-h select-pane -L
      bind-key -T copy-mode-vi C-j select-pane -D
      bind-key -T copy-mode-vi C-k select-pane -U
      bind-key -T copy-mode-vi C-l select-pane -R
      bind-key -T copy-mode-vi 'C-\' select-pane -l

      TMUX_FZF_LAUNCH_KEY="C-f"

      # catppuccin settings
      set -g @catppuccin_flavor "mocha"

      set -g status-left-length 100
      set -g status-left ""
      set -g status-right-length 100

      set -g @catppuccin_status_fill "icon"

      set -g @catppuccin_window_text " #W"
      set -g @catppuccin_window_current_text " #W"
      set -g @catppuccin_window_flags "icon"
      set -g @catppuccin_window_flags_icon_current " "
      set -g @catppuccin_window_flags_icon_zoom " "
      set -g @catppuccin_window_status_style "rounded"
      set -g @catppuccin_window_current_number_color "#{@thm_blue}"

      set -g @catppuccin_status_connect_separator "no"
      set -g @catppuccin_status_left_separator  " "
      set -g @catppuccin_status_right_separator ""

      set -g @catppuccin_directory_text " #(echo '#{pane_current_path}' | rev | cut -d'/' -f-2 | rev)"
      set -g @catppuccin_directory_color "#{E:@thm_mauve}"
      set -g @catppuccin_date_time_text " %d %b %H:%M"

      # NOTE: these plugins are required at the bottom to be configured properly
      # tmuxplugin-catppuccin
      # ---------------------

      run-shell ${pkgs.tmuxPlugins.catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux

      # catppuccin post init settings
      set -g status-right "#{E:@catppuccin_status_session}"
      set -agF status-right "#{E:@catppuccin_status_cpu}"
      set -ag status-right "#{E:@catppuccin_status_directory}#{E:@catppuccin_status_date_time}"

      # tmuxplugin-cpu
      # ---------------------

      run-shell ${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/cpu.tmux

      # tmuxplugin-tmux-nerd-font-window-name
      # ---------------------

      run-shell ${tmux-nerd-font-window-name}/share/tmux-plugins/tmux-nerd-font-window-name/tmux-nerd-font-window-name.tmux

      # set -g "status-format[1]" ""
      # set -g status 2
    '';
  };

  home.packages = with pkgs; [ sesh ];
}
