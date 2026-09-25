return {
  "christoomey/vim-tmux-navigator",
  event = "VeryLazy",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
    "TmuxNavigatorProcessList",
  },
  keys = {
    { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
    { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
    { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
    { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
    { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
  },
  init = function()
    -- Reusable function to register keymaps in different contexts
    local function set_keymaps()
      vim.keymap.set({ "n", "t", "v" }, "<C-h>", "<cmd>TmuxNavigateLeft<cr>")
      vim.keymap.set({ "n", "t", "v" }, "<C-j>", "<cmd>TmuxNavigateDown<cr>")
      vim.keymap.set({ "n", "t", "v" }, "<C-k>", "<cmd>TmuxNavigateUp<cr>")
      vim.keymap.set({ "n", "t", "v" }, "<C-l>", "<cmd>TmuxNavigateRight<cr>")
      vim.keymap.set({ "n", "t", "v" }, "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>")
    end

    -- Register once globally
    set_keymaps()

    -- Tell tmux this pane is running neovim.
    --
    -- vim-tmux-navigator's stock tmux-side check greps
    --   ps -o state= -o comm= -t '#{pane_tty}'
    -- for a vim-like process name. That never matches when atuin's pty-proxy
    -- is enabled: atuin owns the pane tty, so the pane's process tree is
    -- atuin -> zsh -> nvim and ps reports only "atuin". tmux therefore treats
    -- every <C-h/j/k/l> as a pane move and never forwards them to neovim.
    --
    -- Setting a pane-scoped tmux option is deterministic and needs no ps.
    -- The matching `if-shell -F '#{@pane-is-vim}'` bindings live in
    -- home/shell/tmux.nix.
    if vim.env.TMUX and vim.env.TMUX_PANE then
      local pane = vim.env.TMUX_PANE

      local function set_pane_is_vim(on)
        local cmd = on and { "tmux", "set", "-p", "-t", pane, "@pane-is-vim", "on" }
          or { "tmux", "set", "-p", "-t", pane, "-u", "@pane-is-vim" }
        -- pcall: never let a missing/failed tmux abort startup or exit.
        pcall(function()
          vim.system(cmd):wait()
        end)
      end

      set_pane_is_vim(true)

      vim.api.nvim_create_autocmd({ "VimEnter", "VimResume" }, {
        callback = function()
          set_pane_is_vim(true)
        end,
      })

      -- Must clear on exit, or the pane keeps claiming to be vim and C-h/j/k/l
      -- stop moving panes for the shell that follows.
      vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, {
        callback = function()
          set_pane_is_vim(false)
        end,
      })
    end

    -- Re-register for terminal buffers to prevent literal command injection
    -- required for opencode.nvim
    -- https://github.com/nickjvandyke/opencode.nvim/issues/49
    vim.api.nvim_create_autocmd("TermOpen", {
      callback = set_keymaps,
    })
  end,
}
