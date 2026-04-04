{ lib, ... }:
{
  programs.starship = {
    enable = true;
    enableTransience = true;
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";
      format = lib.concatStrings [
        "[](surface0)"
        "$os"
        "$username"
        "[](fg:surface0 bg:mauve)"
        "$directory"
        "[](fg:mauve bg:green)"
        "$git_branch"
        "$git_status"
        "[](fg:green bg:peach)"
        "$c"
        "$rust"
        "$golang"
        "$nodejs"
        "$php"
        "$java"
        "$kotlin"
        "$haskell"
        "$python"
        "[](fg:peach bg:blue)"
        "$time"
        "[ ](fg:blue)"
        "$line_break$characte"
      ];
      palette = "catppuccin_mocha";

      palettes.catppuccin_mocha = {
        red = "#f38ba8";
        maroon = "#eba0ac";
        peach = "#fab387";
        mauve = "#cba6f7";
        green = "#a6e3a1";
        blue = "#89b4fa";
        lavender = "#b4befe";
        text = "#cdd6f4";
        surface0 = "#313244";
        base = "#1e1e2e";
        mantle = "#181825";
      };

      os = {
        disabled = false;
        style = "bg:surface0 fg:text";
      };
      os.symbols = {
        Macos = "";
        NixOS = " ";
        Linux = "";
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
        truncation_symbol = ".../";
      };
      directory.substitutions = {
        "~" = " ~";
        "dev" = " dev";
        "Documents" = " Documents";
        "Downloads" = " Downloads";
      };

      git_branch = {
        symbol = " ";
        style = "bg:green";
        format = "[[ $symbol $branch ](fg:base bg:green)]($style)";
      };
      git_status = {
        style = "bg:green";
        format = "[[($all_status$ahead_behind )](fg:base bg:green)]($style)";
      };

      nodejs  = { symbol = ""; style = "bg:peach"; format = "[[ $symbol( $version) ](fg:base bg:peach)]($style)"; };
      c       = { symbol = " "; style = "bg:peach"; format = "[[ $symbol( $version) ](fg:base bg:peach)]($style)"; };
      rust    = { symbol = ""; style = "bg:peach"; format = "[[ $symbol( $version) ](fg:base bg:peach)]($style)"; };
      golang  = { symbol = ""; style = "bg:peach"; format = "[[ $symbol( $version) ](fg:base bg:peach)]($style)"; };
      php     = { symbol = ""; style = "bg:peach"; format = "[[ $symbol( $version) ](fg:base bg:peach)]($style)"; };
      java    = { symbol = " "; style = "bg:peach"; format = "[[ $symbol( $version) ](fg:base bg:peach)]($style)"; };
      kotlin  = { symbol = ""; style = "bg:peach"; format = "[[ $symbol( $version) ](fg:base bg:peach)]($style)"; };
      haskell = { symbol = ""; style = "bg:peach"; format = "[[ $symbol( $version) ](fg:base bg:peach)]($style)"; };
      python  = { symbol = ""; style = "bg:peach"; format = "[[ $symbol( $version) ](fg:base bg:peach)]($style)"; };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:blue";
        format = "[[   $time ](fg:mantle bg:blue)]($style)";
      };

      line_break.disabled = false;

      character = {
        disabled = false;
        success_symbol = "[](bold fg:green)";
        error_symbol = "[](bold fg:red)";
        vimcmd_symbol = "[](bold fg:green)";
        vimcmd_replace_one_symbol = "[](bold fg:purple)";
        vimcmd_replace_symbol = "[](bold fg:purple)";
        vimcmd_visual_symbol = "[](bold fg:lavender)";
      };
    };
  };
}
