# ======= #
# FZF-TAB
# ======= #
zstyle ':completion:complete:git-checkout:argument-rest' sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 -a --icons=auto --color=always $realpath'
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:complete:cd*' popup-min-size 50 8
