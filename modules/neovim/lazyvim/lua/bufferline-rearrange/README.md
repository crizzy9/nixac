# Bufferline Rearrange

A Neovim plugin that provides a harpoon-like interface for rearranging bufferline buffers.

## Usage

Press `<leader>br` to open the buffer rearrange window.

In the rearrange window:
- Use `dd` to cut/delete a line
- Use `p` to paste the line
- Use standard Vim motions to navigate
- Use `:Wq`, `ZZ`, or `<leader>w` to apply the new buffer order
- Use `:q!`, `<Esc>`, or `q` to cancel without applying changes

## Example

```
# Use dd to delete/cut a line, p to paste
# Use :Wq, ZZ, or <leader>w to apply changes
# Use :q!, q, or Esc to cancel

1: init.lua
2: config/keymaps.lua
3: plugins/options.lua
4: lua/plugins.lua
```

The buffer names are extracted directly from bufferline, so they will show path disambiguation (folder names) when there are duplicate filenames, just like in your bufferline tabs.

Simply rearrange the lines in the order you want, then save to apply the changes.
