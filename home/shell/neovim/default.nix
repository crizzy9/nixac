# Neovim + LazyVim.
#
# Nix owns the binary, the LSP servers, the formatters and the treesitter
# grammars; LazyVim owns the plugin set. The config directory is an
# OUT-OF-STORE symlink to lazyvim/ in this repo so lazy.nvim can write its lock
# file and Mason-style state back — a plain store symlink would be read-only.
#
# Package list ported from lumino's modules/shell/neovim/shared.nix, minus the
# Linux-only clipboard/GL bits (xclip, wl-clipboard, qtdeclarative, libGL).
{
  config,
  lib,
  pkgs,
  host,
  ...
}:
let
  lazyvimPath = "${host.repoDir}/home/shell/neovim/lazyvim";
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withNodeJs = true;

    # Legacy remote-plugin providers. Pinned explicitly rather than inherited
    # from home.stateVersion, so bumping stateVersion can't change them silently.
    #
    # withRuby MUST stay false: it builds a `neovim-ruby-env` in the store and
    # puts it on GEM_PATH for everything neovim spawns. ruby-lsp inherits that,
    # decides the project's bundle lives there, and dies trying to write gems
    # into the read-only Nix store:
    #   Bundler::PermissionError: error while trying to write to
    #   /nix/store/...-neovim-ruby-env/lib/ruby/gems/3.4.0/cache
    # LazyVim uses no Ruby remote plugins, so nothing wants this provider.
    withRuby = false;

    # Python provider: also unused by LazyVim, but harmless and cheap to keep.
    withPython3 = true;

    extraPackages = with pkgs; [
      # ── Lua
      lua
      stylua
      lua-language-server

      # ── Nix
      nil
      statix
      nixfmt

      # ── Shell / config formats
      shfmt
      bash-language-server
      yaml-language-server
      taplo
      marksman
      markdownlint-cli2

      # ── Web / TS
      vtsls
      typescript-language-server
      tailwindcss-language-server
      astro-language-server
      htmx-lsp
      prettier

      # ── Systems / compiled
      gopls
      go
      rust-analyzer
      rustup
      gcc
      clang
      clang-tools
      jdt-language-server

      # ── Ruby (mosaic-api-server: Rails 8 / Ruby 3.4)
      # Mason is disabled in lazyvim/lua/config/lazy.lua, so every LSP must be
      # on PATH from here — an enabled LazyVim extra with no binary silently
      # does nothing.
      ruby-lsp
      rubyPackages_3_4.standard # standardrb — the linter the repo enforces
      rubocop # used by .rubocop-metrics.yml (make check_complexity)

      # ── JS/TS tooling not covered by vtsls
      vscode-langservers-extracted # eslint + json/html/css language servers
      prisma-language-server # mosaic-ai-server prisma schemas

      # ── Containers
      dockerfile-language-server
      docker-compose-language-service

      # ── Python
      basedpyright
      ruff
      (python312.withPackages (ps: with ps; [ pip ]))

      # ── LaTeX
      texlab

      # ── Tooling
      nodejs
      pnpm
      tree-sitter
      ast-grep
    ];

    plugins = [ pkgs.vimPlugins.nvim-treesitter.withAllGrammars ];
  };

  xdg.configFile = {
    # mkForce is required: home-manager's own neovim module sets this to true
    # at normal priority whenever programs.neovim.enable is on, so a plain
    # `false` here is a conflicting definition, not an override. We disable it
    # because LazyVim ships its own init.lua inside the symlinked config dir.
    "nvim/init.lua".enable = lib.mkForce false;
    nvim.source = config.lib.file.mkOutOfStoreSymlink lazyvimPath;
  };

  home.shellAliases = {
    v = "nvim";
    vi = "nvim";
  };
}
