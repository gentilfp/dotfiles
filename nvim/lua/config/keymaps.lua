-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<leader>cp", function()
  local relpath = vim.fn.expand("%")
  vim.fn.setreg("+", relpath)
  vim.notify("Copied: " .. relpath)
end, { noremap = true, silent = true, desc = "Copy Relative File Path to Clipboard" })
