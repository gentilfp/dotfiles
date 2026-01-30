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

-- Close diagnostic floats when switching buffers to prevent frozen dialogs
vim.api.nvim_create_autocmd({ "BufLeave", "BufWinLeave" }, {
  callback = function()
    vim.diagnostic.hide()
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
