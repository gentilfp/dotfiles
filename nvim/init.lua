-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Remove trailing spaces and blank lines on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    -- Remove trailing spaces
    vim.cmd([[silent! %s/\s\+$//e]])
    -- Remove blank lines at the end of the file
    vim.cmd([[silent! %s/\n\+\%$//e]])
  end,
})
