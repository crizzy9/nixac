return {
  "preservim/vimux",
  config = function()
    -- vim.g.VimuxOrientation = "v"
    -- vim.g.VimuxHeight = "25%"
    vim.g.VimuxOrientation = "h"
    vim.g.VimuxHeight = "40%"
  end,
  keys = {
    {
      "\\p",
      function()
        vim.fn.VimuxRunCommand("python " .. vim.fn.expand("%"))
      end,
      desc = "Run Python file in Tmux",
    },
    { "\\u", "<cmd>VimuxRunLastCommand<cr>", desc = "Repeat last Tmux command" },
  },
}
