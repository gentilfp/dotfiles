vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    for _, group in ipairs({ "Normal", "NormalNC", "NormalFloat", "SignColumn", "EndOfBuffer" }) do
      vim.api.nvim_set_hl(0, group, { bg = "none" })
    end
  end,
})

return {
  { "dracula/vim", name = "dracula", priority = 1000 },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "dracula",
    },
  },
}
