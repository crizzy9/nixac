-- mini.nvim gap-fillers
--
-- LazyVim already ships mini.ai, mini.pairs, mini.icons — those continue to
-- load via the LazyVim core spec.
--
-- This file adds 7 mini modules that fill capability gaps in the current
-- setup (no overlap with existing plugins). The commented-out specs at the
-- bottom are alternatives to existing plugins — uncomment to try them, but
-- mind the noted conflicts.

return {
  -- ─────────────────────────────────────────────────────────────────────
  -- Active gap-fillers
  -- ─────────────────────────────────────────────────────────────────────

  -- Align text around a char/regex.  ga / gA in normal & visual.
  {
    "nvim-mini/mini.align",
    version = false,
    event = "VeryLazy",
    opts = {},
  },

  -- Move lines / visual blocks with Alt-h/j/k/l.
  {
    "nvim-mini/mini.move",
    version = false,
    event = "VeryLazy",
    opts = {},
  },

  -- Operators: gm (multiply), gx (exchange), gr (replace w/ register),
  -- gs (sort), g= (evaluate).
  {
    "nvim-mini/mini.operators",
    version = false,
    event = "VeryLazy",
    opts = {},
  },

  -- Split / join function arguments, arrays, etc.  gS toggles.
  {
    "nvim-mini/mini.splitjoin",
    version = false,
    event = "VeryLazy",
    opts = {},
  },

  -- vim-unimpaired-style [x / ]x navigation (buffers, conflicts, diagnostics,
  -- jumps, locationlist, quickfix, treesitter, windows, yank, undo).
  -- Note: [d / ]d will overlap with LazyVim's diagnostic mappings — same
  -- intent, mini's version usually wins. Disable mini's `diagnostic` group
  -- in opts if it causes friction.
  {
    "nvim-mini/mini.bracketed",
    version = false,
    event = "VeryLazy",
    opts = {},
  },

  -- Highlight + clean trailing whitespace.  :Trim removes it.
  {
    "nvim-mini/mini.trailspace",
    version = false,
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },

  -- Delayed-highlight word under cursor (replacement for vim-illuminate /
  -- snacks.words, neither of which is enabled here).
  {
    "nvim-mini/mini.cursorword",
    version = false,
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },

  -- ─────────────────────────────────────────────────────────────────────
  -- Optional alternatives (commented for later trial)
  -- Uncomment a block AND disable the noted conflicting plugin.
  -- ─────────────────────────────────────────────────────────────────────

  -- mini.surround — replaces nvim-surround.lua
  -- Conflict: kylechui/nvim-surround. Disable that plugin first.
  -- {
  --   "nvim-mini/mini.surround",
  --   version = false,
  --   event = "VeryLazy",
  --   opts = {
  --     mappings = {
  --       add = "sa",      -- add surrounding
  --       delete = "sd",   -- delete surrounding
  --       find = "sf",     -- find surrounding (right)
  --       find_left = "sF",
  --       highlight = "sh",
  --       replace = "sr",  -- replace surrounding
  --       update_n_lines = "sn",
  --     },
  --   },
  -- },

  -- mini.hipatterns — TODO/FIXME highlights AND hex color code highlighting.
  -- Conflict: todo-comments.nvim covers TODO highlights; nvim-colorizer
  -- covers hex codes. To run mini.hipatterns instead, disable both.
  -- {
  --   "nvim-mini/mini.hipatterns",
  --   version = false,
  --   event = { "BufReadPost", "BufNewFile" },
  --   config = function()
  --     local hi = require("mini.hipatterns")
  --     hi.setup({
  --       highlighters = {
  --         fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
  --         hack  = { pattern = "%f[%w]()HACK()%f[%W]",  group = "MiniHipatternsHack"  },
  --         todo  = { pattern = "%f[%w]()TODO()%f[%W]",  group = "MiniHipatternsTodo"  },
  --         note  = { pattern = "%f[%w]()NOTE()%f[%W]",  group = "MiniHipatternsNote"  },
  --         hex_color = hi.gen_highlighter.hex_color(), -- #rrggbb codes
  --       },
  --     })
  --   end,
  -- },

  -- mini.diff — gutter diff signs + inline hunk preview.
  -- Conflict: gitsigns.nvim. Disable gitsigns to avoid double signs.
  -- {
  --   "nvim-mini/mini.diff",
  --   version = false,
  --   event = { "BufReadPost", "BufNewFile" },
  --   opts = {},
  -- },

  -- mini.snippets — snippet engine using LSP-style snippets.
  -- Conflict: LuaSnip (LazyVim extra). Also requires hooking into blink.cmp
  -- as the snippet provider. Non-trivial swap.
  -- {
  --   "nvim-mini/mini.snippets",
  --   version = false,
  --   event = "InsertEnter",
  --   opts = {},
  -- },

  -- mini.comment — comment toggling.
  -- Conflict: built-in `gc` (Neovim 0.10+) and ts-comments.nvim. Both are
  -- already comfortable; mini.comment is mostly a sidegrade.
  -- {
  --   "nvim-mini/mini.comment",
  --   version = false,
  --   event = "VeryLazy",
  --   opts = {},
  -- },
}
