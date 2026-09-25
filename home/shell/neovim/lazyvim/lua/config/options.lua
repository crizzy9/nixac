-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Use basedpyright instead of pyright for Python LSP
vim.g.lazyvim_python_lsp = "basedpyright"

-- Patch LazyVim.get_pkg_path to suppress Mason warnings for NixOS system-installed packages
-- https://github.com/LazyVim/LazyVim/issues/4339
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    local original_get_pkg_path = LazyVim.get_pkg_path
    ---@diagnostic disable-next-line: duplicate-set-field
    LazyVim.get_pkg_path = function(pkg, path, opts)
      opts = opts or {}
      opts.warn = false -- Suppress Mason package warnings on NixOS
      return original_get_pkg_path(pkg, path, opts)
    end
  end,
})

-- TODO: RAG service for avante
-- local rag_service = require('avante.rag_service')
-- rag_service.launch_rag_service(function()
--   -- This callback is called when the service is ready
--   print("RAG service is running!")
-- end)
-- rag_service.add_resource("file:///home/nightwatcher/.dotfiles/")

-- Ruby: use standardrb rather than LazyVim's rubocop default.
-- mosaic-api-server enforces standard (.standard.yml, `make lint`, CI), so a
-- bare rubocop would flag hundreds of style violations the project doesn't care
-- about. Must be set here, not in a plugin spec: lazyvim.plugins.extras.lang.ruby
-- reads this global at file-load time.
-- Set to "rubocop" if you pick up a project that uses it instead.
vim.g.lazyvim_ruby_formatter = "standardrb"
vim.g.lazyvim_ruby_lsp = "ruby_lsp"
