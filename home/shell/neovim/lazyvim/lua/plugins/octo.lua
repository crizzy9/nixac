return {
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "ibhagwan/fzf-lua",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      picker = "fzf-lua",
      suppress_missing_scope = {
        projects_v2 = true,
      },
      enable_builtin = true,
      default_remote = { "upstream", "origin" },
      default_merge_method = "squash",
      ssh_aliases = {},
    },
    keys = {
      { "<leader>gi", "<cmd>Octo issue list<cr>", desc = "Issues (Octo)" },
      { "<leader>gp", "<cmd>Octo pr list<cr>", desc = "PRs (Octo)" },
      { "<leader>gP", "<cmd>Octo pr create<cr>", desc = "Create PR (Octo)" },
      { "<leader>gr", "<cmd>Octo review start<cr>", desc = "Start Review (Octo)" },
      { "<leader>gR", "<cmd>Octo review submit<cr>", desc = "Submit Review (Octo)" },
      { "<leader>ga", "<cmd>Octo actions<cr>", desc = "Actions (Octo)" },
      { "<leader>gs", "<cmd>Octo search<cr>", desc = "Search (Octo)" },
    },
  },
}
