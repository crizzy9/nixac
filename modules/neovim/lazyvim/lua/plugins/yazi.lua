return {
  "mikavilpas/yazi.nvim",
  keys = {
    {
      "<leader>y",
      mode = { "n", "v" },
      "<cmd>Yazi<cr>",
      desc = "Open yazi at the current file",
      -- icon = { icon = "", color = "orange" },
    },
    {
      "<leader>Y",
      "<cmd>Yazi cwd<cr>",
      desc = "Open the file manager in nvim's working directory",
      -- icon = { icon = "", color = "orange" },
    },
  },
}
