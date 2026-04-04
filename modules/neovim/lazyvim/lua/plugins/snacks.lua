return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.scroll = { enabled = false }
  end,
  keys = {
    -- { "<leader><leader>", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
    { "<leader>fk", function() require("snacks").bufdelete() end, desc = "Delete Buffer" }
  }
}
