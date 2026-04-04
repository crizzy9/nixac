{ pkgs, ... }:
let
  gvfs = pkgs.yaziPlugins.mkYaziPlugin {
    name = "gvfs";
    pname = "gvfs";
    version = "2025-11-27";
    src = pkgs.fetchFromGitHub {
      owner = "boydaihungst";
      repo = "gvfs.yazi";
      rev = "d4b8d83d37fcb10a53e1ca07f8ee011dff089c91";
      hash = "sha256-6VNra6WUjDfBdGjCw/6VOAaAgZLF78/4Gj47BOh1Q/0=";
    };
  };
  yazi-flavors = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "flavors";
    rev = "3edeb49";
    hash = "sha256-twgXHeIj52EfpMpLrhxjYmwaPnIYah3Zk/gqCNTb2SQ=";
  };
in {
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;

    initLua = ''
      require("git"):setup()
      require("starship"):setup()
      require("full-border"):setup()
    '';

    flavors = { catppuccin-mocha = "${yazi-flavors}/catppuccin-mocha.yazi"; };

    theme = { flavor = { dark = "catppuccin-mocha"; }; };

    keymap = {
      mgr = {
        prepend_keymap = [
          {
            on = [ "g" "i" ];
            run = "plugin lazygit";
            desc = "run lazygit";
          }
          {
            on = "F";
            run = "plugin smart-filter";
            desc = "Smart filter";
          }
          {
            on = "l";
            run = "plugin smart-enter";
            desc = "Enter child directory, or open the file";
          }
          {
            on = "f";
            run = "plugin jump-to-char";
            desc = "Jump to char";
          }
          {
            on = [ "m" ];
            run = "plugin relative-motions";
            desc = "Trigger a new relative motion";
          }
          {
            on = "<C-d>";
            run = "plugin diff";
            desc = "Diff the selected with the hovered file";
          }
          {
            on = [ "g" "m" ];
            run = "plugin mediainfo -- toggle-metadata";
            desc = "Toggle media preview metadata";
          }
        ];
      };
    };

    settings = {
      plugin = {
        prepend_preloaders = [
          {
            mime = "{audio,video,image}/*";
            run = "mediainfo";
          }
          {
            mime = "application/subrip";
            run = "mediainfo";
          }
          {
            mime = "application/postscript";
            run = "mediainfo";
          }
        ];

        prepend_previewers = [
          {
            name = "*/";
            run = ''
              piper -- eza -TL=3 --color=always --icons=always --group-directories-first --no-quotes "$1"'';
          }
          {
            name = "*.md";
            run = ''piper -- CLICOLOR_FORCE=1 glow -w=$w -s=dark "$1"'';
          }
          {
            name = "*.(py|sh|java|yml|yaml|go|toml|conf|nix)";
            run = ''piper -- bat -p --color=always "$1"'';
          }
          {
            name = "*.(csv|*.rst|*.json|*.lock|*.ipynb)";
            run = ''
              piper -- rich -j --left --panel=rounded --guides --line-numbers --force-terminal "$1"'';
          }
          {
            mime = "{audio,video,image}/*";
            run = "mediainfo";
          }
          {
            mime = "application/subrip";
            run = "mediainfo";
          }
          {
            mime = "application/postscript";
            run = "mediainfo";
          }
        ];

        prepend_fetchers = [
          {
            id = "git";
            name = "*";
            run = "git";
          }
          {
            id = "git";
            name = "*/";
            run = "git";
          }
        ];
      };

      mgr = {
        show_hidden = true;
        sort_by = "mtime";
        sort_dir_first = true;
        sort_reverse = true;
      };
    };

    plugins = {
      inherit (pkgs.yaziPlugins)
        git smart-filter smart-enter piper diff lazygit jump-to-char
        relative-motions full-border starship mediainfo;
    };

    extraPackages = with pkgs; [ glow rich-cli mediainfo ];

  };

}
