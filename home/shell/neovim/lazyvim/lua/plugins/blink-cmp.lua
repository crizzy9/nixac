-- LazyVim's default blink.cmp uses preset = "enter" which makes <CR> accept.
-- Override to "default" so Ctrl+Y accepts and Tab cycles. Explicitly clear
-- <CR> in case the preset doesn't fully unset it.
return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      preset = "default",
      ["<CR>"] = {},
    },
  },
}
