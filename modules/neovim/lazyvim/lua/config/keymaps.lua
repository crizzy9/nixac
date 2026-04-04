-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<leader>F", function()
  require("bufferline").move(1)
end, { buffer = buffer, desc = "Move Buffer Right" })
vim.keymap.set("n", "<leader>A", function()
  require("bufferline").move(-1)
end, { buffer = buffer, desc = "Move Buffer Left" })

vim.keymap.set("n", "<leader>i", function()
  require("harpoon"):list():prev()
end, { buffer = buffer, desc = "Harpoon prev" })
vim.keymap.set("n", "<leader>o", function()
  require("harpoon"):list():next()
end, { buffer = buffer, desc = "Harpoon next" })

-- TODO: increment_selection.lua - remap from <C-Space> to <C-a>
-- TODO: Quit current window same as <leader>wd

-- vim.keymap.set("n", "<leader>qw", "", { buffer = buffer, desc = "Quit Window"})

-- vim.keymap.set("n", "<leader>tw", ":%s/\\s\\+$\\e<CR>", { buffer = buffer, desc = "Remove Trailing Whitespace" })
vim.keymap.set("n", "<leader>cm", function()
  if vim.bo.filetype == "python" then
    local lines = {
      'if __name__ == "__main__":',
      "    s = Solution()",
    }
    vim.api.nvim_buf_set_lines(0, -1, -1, false, lines)
  else
    vim.notify("Not a python file", vim.log.levels.WARN)
  end
end, { desc = "Add Python main block" })
