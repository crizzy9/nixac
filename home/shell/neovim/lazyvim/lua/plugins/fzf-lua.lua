return {
  -- fzf-lua as PRIMARY picker
  -- LazyVim's extras.editor.fzf provides all standard keybindings
  -- We only add: display formatting + extra git pickers + full-path overrides
  "ibhagwan/fzf-lua",
  opts = {
    defaults = {
      formatter = "path.filename_first",
    },
    -- path_shorten removed: it shortened paths in the line content fed to fzf,
    -- so search matched against `m/s/c/d/file.lua` instead of full paths.
    -- formatter = "path.filename_first" still gives a clean filename-prominent
    -- display while fzf searches the full path.
    files = {
      formatter = "path.filename_first",
    },
    grep = {
      formatter = "path.filename_first",
    },
    lsp = {
      formatter = "path.filename_first",
    },
  },
  keys = {
    -- Override LazyVim defaults to show full path (no formatter, no shorten)
    { "<leader>fF", function() require("fzf-lua").files({ formatter = false, path_shorten = false, root = false }) end, desc = "Find Files (full path, cwd)" },
    { "<leader>sG", function() require("fzf-lua").live_grep({ formatter = false, path_shorten = false, root = false }) end, desc = "Grep (full path, cwd)" },

    -- Extra git pickers not in LazyVim fzf defaults
    { "<leader>gb", "<cmd>FzfLua git_blame<cr>", desc = "Git Blame" },
    { "<leader>gB", "<cmd>FzfLua git_branches<cr>", desc = "Git Branches" },
    { "<leader>gL", "<cmd>FzfLua git_bcommits<cr>", desc = "Git Log (buffer)" },
  },
}
