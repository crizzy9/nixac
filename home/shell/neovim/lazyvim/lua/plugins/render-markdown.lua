return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {
    pipe_table = {
      cell = "trimmed",
      padding = 1,
      min_width = 0,
      border_virtual = true,
    },
    win_options = {
      wrap = { default = vim.o.wrap, rendered = false },
    },
  },
}
