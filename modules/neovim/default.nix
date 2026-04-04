# Neovim with LazyVim — out-of-store symlink to lazyvim config in this repo.
# The lazyvim/ directory is copied from lumino and lives alongside this file.
{ config, pkgs, lib, ... }:
let
  lazyvimPath = "${config.home.homeDirectory}/nixac/modules/neovim/lazyvim";
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withNodeJs = true;
    extraPackages = with pkgs; [
      # LSP servers
      lua-language-server
      nil
      statix
      gopls
      rust-analyzer
      vtsls
      basedpyright
      jdt-language-server
      yaml-language-server
      bash-language-server
      tailwindcss-language-server
      taplo
      marksman

      # Formatters & linters
      stylua
      shfmt
      nixfmt-rfc-style
      prettierd
      markdownlint-cli2

      # Languages & tools
      lua
      gcc
      go
      nodejs
      pnpm
      (python312.withPackages (ps: with ps; [ pip ]))
      tree-sitter
      ast-grep
    ];
    plugins = [ pkgs.vimPlugins.nvim-treesitter.withAllGrammars ];
  };

  # Symlink nvim config dir out-of-store (so lazy.nvim can write lock files etc.)
  xdg.configFile = {
    "nvim/init.lua".enable = false;
    nvim.source = config.lib.file.mkOutOfStoreSymlink lazyvimPath;
  };

  home.shellAliases = {
    v = "nvim";
    vi = "nvim";
  };
}
