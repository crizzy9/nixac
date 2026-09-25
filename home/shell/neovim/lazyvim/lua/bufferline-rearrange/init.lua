-- TODO: does not work properly sometime especially when moving to the top/bottom of the list
local M = {}

-- Custom name formatter that mimics bufferline's deduplication
local function get_unique_name(bufnr, all_bufnrs)
  local buf_name = vim.api.nvim_buf_get_name(bufnr)

  if buf_name == "" then
    return "[No Name]"
  end

  local filename = vim.fn.fnamemodify(buf_name, ":t")

  -- Check if there are duplicate filenames
  local duplicates = {}
  for _, other_bufnr in ipairs(all_bufnrs) do
    if other_bufnr ~= bufnr then
      local other_name = vim.api.nvim_buf_get_name(other_bufnr)
      local other_filename = vim.fn.fnamemodify(other_name, ":t")
      if other_filename == filename then
        table.insert(duplicates, other_bufnr)
      end
    end
  end

  -- If no duplicates, just return filename
  if #duplicates == 0 then
    return filename
  end

  -- There are duplicates, need to add parent directory
  -- Get path components
  local function get_unique_path(path, other_paths)
    local parts = {}
    for part in string.gmatch(path, "[^/]+") do
      table.insert(parts, part)
    end

    -- Start with filename and add parent directories until unique
    for i = #parts - 1, 1, -1 do
      local candidate = table.concat(vim.list_slice(parts, i, #parts), "/")
      local is_unique = true

      for _, other_path in ipairs(other_paths) do
        if other_path:match(candidate .. "$") then
          is_unique = false
          break
        end
      end

      if is_unique then
        return candidate
      end
    end

    return path
  end

  local other_paths = {}
  for _, dup_bufnr in ipairs(duplicates) do
    table.insert(other_paths, vim.api.nvim_buf_get_name(dup_bufnr))
  end

  return get_unique_path(buf_name, other_paths)
end

-- Get all listed buffers in the order they appear in bufferline
local function get_buffer_list()
  local buffers = {}
  local bufferline_state = require("bufferline.state")

  -- First pass: collect all buffer numbers
  local all_bufnrs = {}
  for _, element in ipairs(bufferline_state.components) do
    if element.type == "buffer" then
      local bufnr = element.id
      if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_option(bufnr, "buflisted") then
        table.insert(all_bufnrs, bufnr)
      end
    end
  end

  -- Second pass: get unique names for each buffer
  for _, element in ipairs(bufferline_state.components) do
    if element.type == "buffer" then
      local bufnr = element.id
      if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_option(bufnr, "buflisted") then
        local name = get_unique_name(bufnr, all_bufnrs)

        table.insert(buffers, {
          bufnr = bufnr,
          name = name,
        })
      end
    end
  end

  return buffers
end

-- Apply the new buffer order
local function apply_buffer_order(lines, original_buffers, original_window, original_buffer)
  local new_order = {}

  -- Parse the lines to get the new order
  for _, line in ipairs(lines) do
    -- Extract buffer number from line format: "bufnr: name"
    local bufnr_str = line:match("^(%d+):")
    if bufnr_str then
      local bufnr = tonumber(bufnr_str)
      if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
        table.insert(new_order, bufnr)
      end
    end
  end

  -- If no valid changes, return
  if #new_order == 0 then
    return
  end

  -- Calculate moves needed to reorder buffers
  -- We'll use the bufferline move API repeatedly to achieve the desired order
  local current_order = vim.tbl_map(function(buf)
    return buf.bufnr
  end, original_buffers)

  -- Simple bubble sort approach using bufferline.move
  for target_idx = 1, #new_order do
    local target_bufnr = new_order[target_idx]

    -- Find current position
    local current_idx = nil
    for i, bufnr in ipairs(current_order) do
      if bufnr == target_bufnr then
        current_idx = i
        break
      end
    end

    if current_idx and current_idx ~= target_idx then
      -- Switch to the buffer we want to move (in the original window)
      if vim.api.nvim_win_is_valid(original_window) then
        vim.api.nvim_win_set_buf(original_window, target_bufnr)
      end

      -- Move it to the correct position
      local moves = target_idx - current_idx
      require("bufferline").move(moves)

      -- Update our tracking array
      table.remove(current_order, current_idx)
      table.insert(current_order, target_idx, target_bufnr)
    end
  end

  -- Restore the original buffer view
  if vim.api.nvim_buf_is_valid(original_buffer) and vim.api.nvim_win_is_valid(original_window) then
    vim.api.nvim_win_set_buf(original_window, original_buffer)
  end
end

-- Open the rearrange buffer
function M.open()
  -- Save the original window and buffer
  local original_window = vim.api.nvim_get_current_win()
  local original_buffer = vim.api.nvim_get_current_buf()

  local buffers = get_buffer_list()

  if #buffers == 0 then
    vim.notify("No buffers to rearrange", vim.log.levels.WARN)
    return
  end

  -- Create the content for the temporary buffer
  local lines = {}
  for _, buf in ipairs(buffers) do
    table.insert(lines, string.format("%d: %s", buf.bufnr, buf.name))
  end

  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "bufferline-rearrange")
  vim.api.nvim_buf_set_option(buf, "modifiable", true)

  -- Set buffer name
  vim.api.nvim_buf_set_name(buf, "Bufferline Rearrange")

  -- Open in a centered floating window
  -- Calculate width based on longest line, with min/max bounds
  local max_line_length = 0
  for _, line in ipairs(lines) do
    max_line_length = math.max(max_line_length, #line)
  end
  local width = math.min(math.max(max_line_length + 4, 60), vim.o.columns - 10)
  local height = math.min(#lines + 4, vim.o.lines - 4)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Rearrange Buffers (dd/p to reorder, ZZ to apply) ",
    title_pos = "center",
  })

  -- Set window options
  vim.api.nvim_win_set_option(win, "cursorline", true)

  -- Add instructions at the top
  local instructions = {
    "# Use dd to delete/cut a line, p to paste",
    "# Use :Wq, ZZ, or <leader>w to apply changes",
    "# Use :q!, q, or Esc to cancel",
    "",
  }
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, instructions)

  -- Move cursor to first buffer line
  vim.api.nvim_win_set_cursor(win, { #instructions + 1, 0 })

  -- Create a function to apply the changes
  local function apply_changes()
    local all_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local buffer_lines = {}

    -- Skip instruction lines (lines starting with # or empty)
    for _, line in ipairs(all_lines) do
      if line ~= "" and not line:match("^#") then
        table.insert(buffer_lines, line)
      end
    end

    -- Close the window first to avoid it showing in the main window
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end

    -- Small delay to ensure window is closed before applying changes
    vim.defer_fn(function()
      apply_buffer_order(buffer_lines, buffers, original_window, original_buffer)
      vim.notify("Buffer order updated!", vim.log.levels.INFO)
    end, 10)
  end

  -- Set up buffer-local commands
  vim.api.nvim_buf_create_user_command(buf, "W", function()
    apply_changes()
  end, {})

  vim.api.nvim_buf_create_user_command(buf, "Wq", function()
    apply_changes()
  end, {})

  vim.api.nvim_buf_create_user_command(buf, "WQ", function()
    apply_changes()
  end, {})

  -- Set up keymaps
  local opts = { buffer = buf, silent = true }

  vim.keymap.set("n", "ZZ", function()
    apply_changes()
  end, opts)

  vim.keymap.set("n", "<leader>w", function()
    apply_changes()
  end, opts)

  vim.keymap.set("n", "q", "<cmd>quit!<cr>", opts)
  vim.keymap.set("n", "<Esc>", "<cmd>quit!<cr>", opts)
end

function M.setup()
  -- Setup code if needed
  return M
end

return M
