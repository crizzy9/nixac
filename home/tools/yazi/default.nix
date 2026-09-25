# Yazi file manager. Copied verbatim from lumino modules/shell/yazi/.
{ pkgs, ... }:
let
  # eza-preview = pkgs.yaziPlugins.mkYaziPlugin {
  #   name = "eza-preview";
  #   pname = "eza-preview";
  #   version = "2025-11-27";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "cristianvasquez";
  #     repo = "eza-preview.yazi";
  #     rev = "d087ad8";
  #     hash = "sha256-y9lKlnBgYsazugWUqtIql9KXjQ08zMMHawxFVALaQxk=";
  #   };
  # };
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
    rev = "36c49acfd7d3924bd751fd74e37b6ff438af691a";
    hash = "sha256-IK0Ye/EPjOGC+//HpjExVTAKfXtlgOrYbFLrhy/DF6k=";
  };
  git-ignore-toggle = pkgs.writeTextDir "main.lua" ''
    --- @since 26.5.6
    local M = {}

    local state_dir = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/yazi"
    local state_file = state_dir .. "/git-ignore-toggle"

    local function read_enabled()
      local file = io.open(state_file, "r")
      if not file then
        return false
      end

      local value = file:read("*a") or ""
      file:close()
      return value:match("^%s*hide") ~= nil
    end

    local function write_enabled(enabled)
      Command("mkdir"):arg({ "-p", state_dir }):status()

      local file = io.open(state_file, "w")
      if file then
        file:write(enabled and "hide\n" or "show\n")
        file:close()
      end
    end

    local snapshot = ya.sync(function(state)
      if state.enabled == nil then
        state.enabled = read_enabled()
      end

      local cwd = cx.active.current.cwd
      -- yazi 26.x moved Url.is_search/is_regular/domain onto Url.spec.*
      -- (the old names still work but log a deprecation warning on every start)
      local regular_cwd = cwd.spec.is_search and Url(cwd.path) or cwd
      return {
        enabled = state.enabled,
        applied = state.applied,
        cwd = regular_cwd,
        cwd_key = tostring(regular_cwd),
      }
    end)

    local toggle_enabled = ya.sync(function(state)
      if state.enabled == nil then
        state.enabled = read_enabled()
      end

      state.enabled = not state.enabled
      state.applied = nil
      return state.enabled
    end)

    local mark_applied = ya.sync(function(state, cwd_key)
      state.applied = cwd_key
    end)

    local clear_applied = ya.sync(function(state)
      state.applied = nil
    end)

    local function apply(force)
      local state = snapshot()
      if not state.enabled then
        return
      end

      if not force and state.applied == state.cwd_key then
        return
      end

      mark_applied(state.cwd_key)
      ya.emit("search_do", { ".", via = "fd", args = "--max-depth=1", ["in"] = state.cwd })
      ya.emit("peek", { force = true })
    end

    function M:setup(opts)
      opts = opts or {}
      local color = opts.color or "yellow"
      local order = opts.order or 9000

      Header:children_add(function()
        local state = snapshot()
        if not state.enabled then
          return ui.Line {}
        end

        if state.applied ~= state.cwd_key then
          ya.emit("plugin", { "git-ignore-toggle", "apply" })
        end

        return ui.Line { ui.Span(" [GI]"):fg(color):bold() }
      end, order, Header.LEFT)
    end

    function M:entry(job)
      local args = job.args or {}
      if args[1] == "apply" then
        return apply(false)
      end

      local enabled = toggle_enabled()
      write_enabled(enabled)

      if enabled then
        ya.notify { title = "Yazi", content = "Git-ignored files hidden", timeout = 2, level = "info" }
        apply(true)
      else
        ya.notify { title = "Yazi", content = "Git-ignored files shown", timeout = 2, level = "info" }
        clear_applied()
        ya.emit("search_stop", {})
        ya.emit("peek", { force = true })
      end
    end

    return M
  '';
  git-ignored-preview = pkgs.writeShellScript "yazi-gitignored-preview" ''
    set -euo pipefail

    state_file="''${XDG_STATE_HOME:-''${HOME}/.local/state}/yazi/git-ignore-toggle"
    args=(-TL=3 --color=always --icons=always --group-directories-first --no-quotes)

    if [ -r "$state_file" ] && grep -qx "hide" "$state_file"; then
      args+=(--git-ignore)
    fi

    exec ${pkgs.eza}/bin/eza "''${args[@]}" "$1"
  '';
in
{
  programs.yazi = {
    enable = true;

    # Legacy default for home.stateVersion < 26.05, pinned explicitly to
    # silence the change-of-default warning. `y` is already a plain alias to
    # yazi in shell/zsh; `yy` is the cwd-changing wrapper.
    shellWrapperName = "yy";

    # TODO: fix the padding issues with starship prompt with tmux and yazi tabs or switch to yatline
    initLua = ''
      require("git"):setup()
      require("git-ignore-toggle"):setup()
      require("starship"):setup()
      require("full-border"):setup()
      -- require("eza-preview"):setup({})
    '';

    flavors = {
      catppuccin-mocha = "${yazi-flavors}/catppuccin-mocha.yazi";
    };

    theme = {
      flavor = {
        dark = "catppuccin-mocha";
      };
    };

    keymap = {
      mgr = {
        # keymap = [];
        prepend_keymap = [
          {
            on = [
              "g"
              "i"
            ];
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
          # {
          #   on = [ "E" ];
          #   run = "plugin eza-preview";
          #   desc = "Toggle tree/list dir preview";
          # }
          # {
          #   on = [ "-" ];
          #   run = "plugin eza-preview --args='--inc-level'";
          #   desc = "Increment tree level";
          # }
          # {
          #   on = [ "_" ];
          #   run = "plugin eza-preview --args='--dec-level'";
          #   desc = "Decrement tree level";
          # }
          # {
          #   on = [ "$" ];
          #   run = "plugin eza-preview --args='--toggle-follow-symlinks'";
          #   desc = "Toggle tree follow symlinks";
          # }
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
            on = [
              "g"
              "m"
            ];
            run = "plugin mediainfo -- toggle-metadata";
            desc = "Toggle media preview metadata";
          }
          {
            on = [
              "g"
              "I"
            ];
            run = "plugin git-ignore-toggle";
            desc = "Toggle gitignored files";
          }
        ];
      };
    };

    settings = {
      plugin = {
        prepend_preloaders = [
          # Replace magick, image, video with mediainfo
          {
            mime = "{audio,video,image}/*";
            run = "mediainfo";
          }
          {
            mime = "application/subrip";
            run = "mediainfo";
          }
          # Adobe Illustrator, Adobe Photoshop is image/adobe.photoshop, already handled above
          {
            mime = "application/postscript";
            run = "mediainfo";
          }
        ];

        prepend_previewers = [
          {
            url = "*/";
            run = ''piper -- ${git-ignored-preview} "$1"'';
          }
          {
            url = "*.md";
            run = ''piper -- CLICOLOR_FORCE=1 glow -w=$w -s=dark "$1"'';
          }
          {
            url = "*.(py|sh|java|yml|yaml|go|toml|conf|nix)";
            run = ''piper -- bat -p --color=always "$1"'';
          }
          {
            url = "*.(csv|*.rst|*.json|*.lock|*.ipynb)";
            run = ''piper -- rich -j --left --panel=rounded --guides --line-numbers --force-terminal "$1"'';
          }
          # Replace magick, image, video with mediainfo
          {
            mime = "{audio,video,image}/*";
            run = "mediainfo";
          }
          {
            mime = "application/subrip";
            run = "mediainfo";
          }
          # Adobe Illustrator, Adobe Photoshop is image/adobe.photoshop, already handled above
          {
            mime = "application/postscript";
            run = "mediainfo";
          }
        ];

        prepend_fetchers = [
          {
            url = "*";
            run = "git";
            group = "git";
          }
          {
            url = "*/";
            run = "git";
            group = "git";
          }
        ];
      };

      mgr = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
        sort_reverse = true;
      };
    };

    plugins = {
      inherit git-ignore-toggle;
      inherit (pkgs.yaziPlugins)
        git
        smart-filter
        smart-enter
        piper
        diff
        lazygit
        jump-to-char
        relative-motions
        full-border
        starship
        mediainfo
        ;
      # eza-preview, glow, rich-preview replaced with piper
      # inherit (pkgs.yaziPlugins) rsync;
      # inherit eza-preview;
      # inherit gvfs;
    };

    extraPackages = with pkgs; [
      glow
      rich-cli
      mediainfo
    ];

  };

}
