-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Disable inline diagnostics (virtual text) - runs after LazyVim config
vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  float = {
    border = "rounded",
    source = true,
  },
})

-- Show diagnostics in floating window when cursor holds on a line
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.diagnostic.open_float(nil, { focusable = false, scope = "cursor" })
  end,
})

-- Don't add newline at end of YAML files
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "yaml", "yml" },
  callback = function()
    vim.opt_local.fixendofline = false
  end,
})

-- Disable spelling for markdown files
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "md" },
  callback = function()
    vim.opt_local.spell = false
  end,
})
