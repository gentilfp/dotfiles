-- Copy relative path
vim.keymap.set("n", "<leader>cp", function()
  local relpath = vim.fn.expand("%:~:.")
  vim.fn.setreg("+", relpath) -- Set it to the clipboard
  vim.notify("Copied relative path: " .. relpath)
end, { noremap = true, silent = true, desc = "Copy Relative File Path to Clipboard" })

-- Set tabs to go forward and backward in buffers
vim.keymap.set("n", "<Tab>", ":bnext<CR>", { noremap = true, silent = true, desc = "Próximo buffer" })
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", { noremap = true, silent = true, desc = "Buffer anterior" })
