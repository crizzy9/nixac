return {
  -- tv.nvim as SECONDARY picker — specialty channels only
  -- fzf-lua is the primary picker for files, grep, LSP, git, etc.
  -- tv.nvim kept for unique channels: system, NixOS, env, SSH, etc.
  {
    "alexpasmantier/tv.nvim",
    lazy = false,
    config = function()
      require("tv").setup({})

      -- Helper: launch tv in a tmux floating popup, open result in neovim
      _G.tv_tmux_popup = function(channel, opts)
        opts = opts or {}
        if vim.env.TMUX then
          local tmp = vim.fn.tempname()
          local cmd = string.format(
            "tmux display-popup -E -w 80%% -h 80%% -T ' tv %s ' 'tv %s > %s'",
            channel, channel, tmp
          )
          vim.fn.system(cmd)
          local result = vim.fn.readfile(tmp)
          vim.fn.delete(tmp)
          if #result > 0 then
            for _, line in ipairs(result) do
              local file, lnum, col = line:match("^(.+):(%d+):(%d+):")
              if file and lnum then
                vim.cmd("edit " .. vim.fn.fnameescape(file))
                vim.api.nvim_win_set_cursor(0, { tonumber(lnum), tonumber(col) - 1 })
              else
                vim.cmd("edit " .. vim.fn.fnameescape(line))
              end
            end
          end
        else
          vim.cmd("Tv " .. channel)
        end
      end
    end,
    keys = {
      -- Channel browser
      { "<leader>tv", function() tv_tmux_popup("channels") end, desc = "tv (all channels)" },
      -- System/infra channels (unique to tv.nvim)
      { "<leader>Ts", function() tv_tmux_popup("systemd-units") end, desc = "Systemd Units (tv)" },
      { "<leader>Tn", function() tv_tmux_popup("nixos-services") end, desc = "NixOS Services (tv)" },
      { "<leader>TN", function() tv_tmux_popup("nixos-generations") end, desc = "NixOS Generations (tv)" },
      { "<leader>Tp", function() tv_tmux_popup("ports") end, desc = "Ports (tv)" },
      { "<leader>TP", function() tv_tmux_popup("procs") end, desc = "Processes (tv)" },
      { "<leader>Te", function() tv_tmux_popup("env") end, desc = "Environment Variables (tv)" },
      { "<leader>Ta", function() tv_tmux_popup("alias") end, desc = "Aliases (tv)" },
      { "<leader>Th", function() tv_tmux_popup("ssh-hosts") end, desc = "SSH Hosts (tv)" },
      { "<leader>Tf", function() tv_tmux_popup("flake-inputs") end, desc = "Flake Inputs (tv)" },
      { "<leader>Td", function() tv_tmux_popup("dotfiles") end, desc = "Dotfiles (tv)" },
      { "<leader>Tt", function() tv_tmux_popup("todo-comments") end, desc = "Todo Comments (tv)" },
    },
  },
}
