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
        if vim.bo.filetype ~= "python" then
          vim.notify("The Vimux Python runner only supports Python buffers", vim.log.levels.WARN)
          return
        end

        local file = vim.fn.expand("%:p")
        if file == "" then
          vim.notify("The current buffer has no file path", vim.log.levels.ERROR)
          return
        end

        local directory = vim.fs.dirname(file)
        local python

        while directory do
          for _, environment in ipairs({ ".venv", "venv" }) do
            local candidate = vim.fs.joinpath(directory, environment, "bin", "python")
            if vim.fn.executable(candidate) == 1 then
              python = candidate
              break
            end
          end

          if python or vim.uv.fs_stat(vim.fs.joinpath(directory, ".git")) then
            break
          end

          local parent = vim.fs.dirname(directory)
          if parent == directory then
            break
          end
          directory = parent
        end

        python = python or vim.fn.exepath("python")
        if python == "" then
          vim.notify("Python is not available in the project or Neovim's PATH", vim.log.levels.ERROR)
          return
        end

        vim.fn.VimuxRunCommand(vim.fn.shellescape(python) .. " " .. vim.fn.shellescape(file))
      end,
      desc = "Run Python file in Tmux",
    },
    { "\\u", "<cmd>VimuxRunLastCommand<cr>", desc = "Repeat last Tmux command" },
  },
}
