# Starship prompt — catppuccin mocha powerline.
#
# Copied byte-for-byte from lumino's modules/shell/starship.nix rather than
# retyped: the format string and symbols are almost entirely Private-Use-Area
# glyphs (U+E0B0 powerline separators, U+F0xx icons) which do not survive being
# rewritten by hand. Three deltas from lumino, all deliberate:
#   • "$line_break$characte" -> "$character"  (lumino bug: the prompt character
#     module was silently never rendered)
#   • character.vimcmd_symbol "fg:creen" -> "fg:green"  (lumino bug)
#   • directory.substitutions: "lumino"/".dotfiles" -> "nixac"
# The first two are worth backporting to lumino.
{
  pkgs,
  lib,
  ...
}:
{
  programs.starship.enable = true;

  # TODO: enable transient prompt for zsh
  # https://starship.rs/advanced-config/#transientprompt-and-transientrightprompt-in-bash
  programs.starship.enableTransience = true; # NOTE: only works for fish

  # programs.starship.settings = pkgs.lib.importTOML ./starship.toml;
  programs.starship.settings = {
    "$schema" = "https://starship.rs/config-schema.json";
    format = lib.concatStrings [
      "[](surface0)"
      "$os"
      "$username"
      "[](fg:surface0 bg:mauve)"
      "$directory"
      "[](fg:mauve bg:green)"
      "$git_branch"
      "$git_status"
      "[](fg:green bg:peach)"
      "$c"
      "$rust"
      "$golang"
      "$nodejs"
      "$php"
      "$java"
      "$kotlin"
      "$haskell"
      "$python"
      # "[](fg:peach bg:maroon)"
      # "$docker_context"
      "[](fg:peach bg:blue)"
      "$time"
      "[ ](fg:blue)"
      "$line_break$character"
    ];
    palette = "catppuccin_mocha";

    # palettes.gruvbox_dark = {
    #   color_fg0 = "#fbf1c7";
    #   color_bg1 = "#3c3836";
    #   color_bg3 = "#665c54";
    #   color_blue = "#458588";
    #   color_aqua = "#689d6a";
    #   color_green = "#98971a";
    #   color_orange = "#d65d0e";
    #   color_purple = "#b16286";
    #   color_red = "#cc241d";
    #   color_yellow = "#d79921";
    # };

    # palettes.tokyo_dark_terminal = {
    #
    # };

    palettes.catppuccin_mocha = {
      # rosewater = "#f5e0dc";
      # flamingo = "#f2cdcd";
      # pink = "#f5c2e7";
      # violet = "#cba6f7";
      red = "#f38ba8";
      maroon = "#eba0ac"; # NOTE: changed teal to maroon
      peach = "#fab387";
      mauve = "#cba6f7";
      # yellow = "#f9e2af";
      green = "#a6e3a1";
      # teal = "#94e2d5";
      # sky = "#89dceb";
      # sapphire = "#74c7ec";
      blue = "#89b4fa";
      lavender = "#b4befe";
      text = "#cdd6f4";
      # subtext1 = "#bac2de";
      # subtext0 = "#a6adc8";
      # overlay2 = "#9399b2";
      # overlay1 = "#7f849c";
      # overlay0 = "#6c7086";
      # surface2 = "#585b70";
      # surface1 = "#45475a";
      surface0 = "#313244";
      base = "#1e1e2e";
      mantle = "#181825";
      # crust = "#11111b";
    };

    os = {
      disabled = false;
      style = "bg:surface0 fg:text";
    };

    os.symbols = {
      Windows = "󰍲";
      Ubuntu = "󰕈";
      SUSE = "";
      Raspbian = "󰐿";
      Mint = "󰣭";
      Macos = "";
      Manjaro = "";
      Linux = "󰌽";
      Gentoo = "󰣨";
      Fedora = "󰣛";
      Alpine = "";
      Amazon = "";
      Android = "";
      Arch = "󰣇";
      Artix = "󰣇";
      CentOS = "";
      Debian = "󰣚";
      NixOS = " ";
      Redhat = "󱄛";
      RedHatEnterprise = "󱄛";
    };

    username = {
      show_always = true;
      style_user = "bg:surface0 fg:text";
      style_root = "bg:surface0 fg:text";
      format = "[ $user ]($style)";
    };

    directory = {
      style = "fg:mantle bg:mauve";
      format = "[ $path ]($style)";
      truncation_length = 3;
      truncation_symbol = "…/";
    };

    directory.substitutions = {
      "~" = " ~";
      "nixac" = " nixac";
      "dev" = "󰲋 dev";
      "Documents" = "󰈙 Documents";
      "Downloads" = " Downloads";
      "Music" = "󰝚 Music";
      "Pictures" = " Pictures";
    };

    git_branch = {
      symbol = " ";
      style = "bg:green";
      format = "[[ $symbol $branch ](fg:base bg:green)]($style)";
    };

    git_status = {
      style = "bg:green";
      format = "[[($all_status$ahead_behind )](fg:base bg:green)]($style)";
    };

    nodejs = {
      symbol = "";
      style = "bg:peach";
      format = "[[ $symbol( $version) ](fg:base bg:peach)]($style)";
    };

    c = {
      symbol = " ";
      style = "bg:peach";
      format = "[[ $symbol( $version) ](fg:base bg:peach)]($style)";
    };

    rust = {
      symbol = "";
      style = "bg:peach";
      format = "[[ $symbol( $version) ](fg:base bg:peach)]($style)";
    };

    golang = {
      symbol = "";
      style = "bg:peach";
      format = "[[ $symbol( $version) ](fg:base bg:peach)]($style)";
    };

    php = {
      symbol = "";
      style = "bg:peach";
      format = "[[ $symbol( $version) ](fg:base bg:peach)]($style)";
    };

    java = {
      symbol = " ";
      style = "bg:peach";
      format = "[[ $symbol( $version) ](fg:base bg:peach)]($style)";
    };

    kotlin = {
      symbol = "";
      style = "bg:peach";
      format = "[[ $symbol( $version) ](fg:base bg:peach)]($style)";
    };

    haskell = {
      symbol = "";
      style = "bg:peach";
      format = "[[ $symbol( $version) ](fg:base bg:peach)]($style)";
    };

    python = {
      symbol = "";
      style = "bg:peach";
      format = "[[ $symbol( $version) ](fg:base bg:peach)]($style)";
    };

    # docker_context = {
    #   symbol = "";
    #   style = "bg:mantle";
    #   format = "[[ $symbol( $context) ](fg:#83a598 bg:color_bg3)]($style)";
    # };

    time = {
      disabled = false;
      time_format = "%R";
      style = "bg:blue";
      format = "[[   $time ](fg:mantle bg:blue)]($style)";
    };

    line_break.disabled = false;

    character = {
      disabled = false;
      success_symbol = "[](bold fg:green)";
      error_symbol = "[](bold fg:red)";
      vimcmd_symbol = "[](bold fg:green)";
      vimcmd_replace_one_symbol = "[](bold fg:purple)";
      vimcmd_replace_symbol = "[](bold fg:purple)";
      vimcmd_visual_symbol = "[](bold fg:lavender)";
    };
  };
}
