return {
  "jiaoshijie/undotree",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = "VeryLazy",
  config = true,
  keys = {
    -- load the plugin only when using its keybindings
    { "<leader>uu", function() require('undotree').toggle() end, desc = "[U]ndo Tree" },
  },
}
