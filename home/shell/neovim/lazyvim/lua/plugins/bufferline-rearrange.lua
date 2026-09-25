return {
  {
    "akinsho/bufferline.nvim",
    keys = {
      {
        "<leader>br",
        function()
          require("bufferline-rearrange").open()
        end,
        desc = "Rearrange Buffers",
      },
    },
  },
  {
    dir = vim.fn.stdpath("config") .. "/lua/bufferline-rearrange",
    name = "bufferline-rearrange",
    config = function()
      require("bufferline-rearrange").setup()
    end,
  },
}
