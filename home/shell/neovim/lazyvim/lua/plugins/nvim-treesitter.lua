return {
  {
    "nvim-treesitter/nvim-treesitter",

    -- Pin to f7955203: commit 8cdffc6d added "tab" to vim query but parser
    -- doesn't support it yet. See: [github.com/nvim-treesitter/nvim-treesitter](http://github.com/nvim-treesitter/nvim-treesitter)
    -- Remove this pin once vim parser is updated with :tab support.
    commit = "f795520",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "qmljs" })
      end
    end,
    init = function()
      vim.filetype.add({
        extension = {
          qml = "qml",
        },
      })
    end,
  },
}
