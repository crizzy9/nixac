-- Helper function to find NixOS-packaged binaries even when a venv/uv shim shadows PATH.
local function get_nix_bin_path(bin_name)
  for dir in (vim.env.PATH or ""):gmatch("[^:]+") do
    if dir:match("^/nix/store/") then
      local candidate = dir .. "/" .. bin_name
      if vim.fn.executable(candidate) == 1 then
        return candidate
      end
    end
  end

  local bin_path = vim.fn.exepath(bin_name)
  if bin_path ~= "" and bin_path:match("^/nix/store/") then
    return bin_path
  end
  return nil
end

-- Helper function to get NixOS package path from binary
local function get_nix_pkg_path(bin_name, subpath)
  local bin_path = get_nix_bin_path(bin_name) or vim.fn.exepath(bin_name)
  if bin_path ~= "" then
    local store_path = bin_path:match("(.*/nix/store/[^/]+)")
    if store_path then
      return store_path .. (subpath or "")
    end
  end
  return nil
end

-- Get TypeScript SDK path from vtsls package
local function get_typescript_sdk_path()
  local vtsls_path = get_nix_pkg_path("vtsls", "/lib/vtsls-language-server/node_modules/.pnpm")
  if vtsls_path then
    -- Find the typescript directory in pnpm store
    local handle = io.popen("find " .. vtsls_path .. " -maxdepth 2 -type d -name 'typescript@*' 2>/dev/null | head -1")
    if handle then
      local result = handle:read("*a")
      handle:close()
      result = result:gsub("%s+$", "") -- trim whitespace
      if result ~= "" then
        return result .. "/node_modules/typescript/lib"
      end
    end
  end
  return nil
end

return {
  -- Astro support (manual config to avoid Mason warnings on NixOS)
  -- https://github.com/LazyVim/LazyVim/issues/4339
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "astro", "css" } },
  },

  -- NixOS LSP server tweaks
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local tsdk = get_typescript_sdk_path()
      local ruff = get_nix_bin_path("ruff")

      opts.servers = opts.servers or {}
      if ruff then
        opts.servers.ruff = vim.tbl_deep_extend("force", opts.servers.ruff or {}, {
          cmd = { ruff, "server" },
        })
      end
      opts.servers.astro = {
        init_options = {
          typescript = {
            tsdk = tsdk,
          },
        },
      }
    end,
  },

  -- Configure vtsls ts-plugin for Astro TypeScript support
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local ts_plugin_path =
        get_nix_pkg_path("astro-ls", "/lib/node_modules/astro-language-server/packages/language-tools/language-server")
      if ts_plugin_path and opts.servers and opts.servers.vtsls then
        LazyVim.extend(opts.servers.vtsls, "settings.vtsls.tsserver.globalPlugins", {
          {
            name = "@astrojs/ts-plugin",
            location = ts_plugin_path,
            enableForWorkspaceTypeScriptVersions = true,
          },
        })
      end
    end,
  },

  -- Formatting with Nix-managed binaries
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.python = { "ruff_format" }

      if LazyVim.has_extra("formatting.prettier") then
        opts.formatters_by_ft.astro = { "prettier" }
      end

      local ruff = get_nix_bin_path("ruff")
      if ruff then
        opts.formatters = opts.formatters or {}
        for _, formatter in ipairs({ "ruff", "ruff_fix", "ruff_format", "ruff_organize_imports" }) do
          opts.formatters[formatter] =
            vim.tbl_deep_extend("force", opts.formatters[formatter] or {}, { command = ruff })
        end
      end
    end,
  },

  -- QML and other LSP configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- QML Language Server
        qmlls = {
          filetypes = { "qml" },
        },
        -- C/C++ Language Server
        -- ccls = {
        --   cmd = { "ccls" },
        --   filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
        --   root_dir = function(fname)
        --     local util = require("lspconfig.util")
        --     return util.root_pattern("compile_commands.json", ".ccls", ".git")(fname)
        --       or util.find_git_ancestor(fname)
        --       or util.path.dirname(fname)
        --   end,
        --   init_options = {
        --     cache = {
        --       directory = vim.fn.stdpath("cache") .. "/ccls",
        --     },
        --     compilationDatabaseDirectory = "build",
        --     index = {
        --       threads = 0,
        --     },
        --     clang = {
        --       excludeArgs = { "-frounding-math" },
        --     },
        --   },
        --   settings = {},
        -- },
      },
    },
    init = function()
      -- Disable diagnostics for QML files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "qml",
        callback = function()
          vim.diagnostic.enable(false, { bufnr = 0 })
        end,
      })
    end,
  },
}
