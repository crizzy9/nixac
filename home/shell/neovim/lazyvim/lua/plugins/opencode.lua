local opencode_cmd = "opencode --port"
local opencode_scroll_up = string.char(27, 21)
local opencode_scroll_down = string.char(27, 4)

local function send_opencode_input(input, buffer)
  if not buffer then
    local terminal = require("snacks.terminal").get(opencode_cmd, { create = false })
    buffer = terminal and terminal.buf or nil
  end

  local job = buffer and vim.b[buffer].terminal_job_id or nil
  if job then
    vim.api.nvim_chan_send(job, input)
  end
end

---@type snacks.terminal.Opts
local opencode_terminal_opts = {
  win = {
    position = "right",
    enter = false,
    on_buf = function(win)
      local function map_scroll(lhs, input, desc)
        vim.keymap.set({ "n", "t" }, lhs, function()
          send_opencode_input(input, win.buf)
        end, {
          buffer = win.buf,
          desc = desc,
          nowait = true,
          silent = true,
        })
      end

      -- Send OpenCode's own half-page keybinds; wheel bursts must not enter opencode.nvim discovery.
      map_scroll("<ScrollWheelUp>", opencode_scroll_up, "Scroll OpenCode up")
      map_scroll("<ScrollWheelDown>", opencode_scroll_down, "Scroll OpenCode down")
      map_scroll("<S-C-u>", opencode_scroll_up, "Scroll OpenCode up")
      map_scroll("<S-C-d>", opencode_scroll_down, "Scroll OpenCode down")
    end,
  },
}

local function toggle_opencode()
  require("snacks.terminal").toggle(opencode_cmd, opencode_terminal_opts)
end

return {
  {
    "NickvanDyke/opencode.nvim",
    version = "*",
    dependencies = {
      {
        "folke/snacks.nvim",
        opts = {
          input = { enabled = true },
          picker = {
            enabled = true,
            win = {
              input = {
                keys = {
                  ["<a-o>"] = { "opencode_send", mode = { "n", "i" } },
                },
              },
            },
            actions = {
              opencode_send = function(picker)
                local items = vim.tbl_map(function(item)
                  return item.file
                      and require("opencode").format({ path = item.file, from = item.pos, to = item.end_pos })
                    or item.text
                end, picker:selected({ fallback = true }))

                require("opencode").prompt(table.concat(items, ", ") .. " ")
              end,
            },
          },
        },
      },
    },
    init = function()
      vim.g.opencode_opts = {
        server = {
          start = function()
            -- Commands can race during startup; reuse the terminal instead of spawning one per command.
            require("snacks.terminal").get(opencode_cmd, opencode_terminal_opts)
          end,
        },
      }
    end,
    config = function()
      local opencode = require("opencode")

      vim.keymap.set("n", "<leader>at", toggle_opencode, { desc = "Toggle OpenCode" })
      vim.keymap.set({ "n", "t" }, "<C-.>", toggle_opencode, { desc = "Toggle OpenCode" })
      vim.keymap.set({ "n", "x" }, "<leader>aA", function()
        opencode.ask()
      end, { desc = "Ask OpenCode" })
      vim.keymap.set({ "n", "x" }, "<leader>aa", function()
        opencode.ask("@this: ")
      end, { desc = "Ask OpenCode about this" })
      vim.keymap.set("n", "<leader>an", function()
        opencode.command("session.new")
      end, { desc = "New OpenCode session" })
      vim.keymap.set("n", "<S-C-u>", function()
        send_opencode_input(opencode_scroll_up)
      end, { desc = "Scroll OpenCode up" })
      vim.keymap.set("n", "<S-C-d>", function()
        send_opencode_input(opencode_scroll_down)
      end, { desc = "Scroll OpenCode down" })
      vim.keymap.set({ "n", "x" }, "<leader>as", function()
        opencode.select()
      end, { desc = "Select OpenCode action" })
      vim.keymap.set("n", "<leader>ae", function()
        opencode.prompt("Explain @this and its context")
      end, { desc = "Explain this code" })
      vim.keymap.set({ "n", "x" }, "go", function()
        return opencode.operator("@this ")
      end, { desc = "Append range to OpenCode", expr = true })
      vim.keymap.set("n", "goo", function()
        return opencode.operator("@this ") .. "_"
      end, { desc = "Append line to OpenCode", expr = true })

      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("opencode_terminal", { clear = true }),
        pattern = "OpencodeEvent:tui.command.execute",
        callback = function(args)
          local event = args.data.event
          if event.properties.command == "prompt.submit" then
            local terminal = require("snacks.terminal").get(opencode_cmd, { create = false })
            if terminal then
              terminal:show()
            end
          end
        end,
      })
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.sections = opts.sections or {}
      opts.sections.lualine_z = opts.sections.lualine_z or {}
      table.insert(opts.sections.lualine_z, 1, function()
        return require("opencode").statusline()
      end)
    end,
  },
}
