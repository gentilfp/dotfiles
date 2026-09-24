vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    for _, group in ipairs({ "Normal", "NormalNC", "NormalFloat", "SignColumn", "EndOfBuffer" }) do
      vim.api.nvim_set_hl(0, group, { bg = "none" })
    end
  end,
})

return {
  {
    "metalelf0/black-metal-theme-neovim",
    name = "black-metal",
    lazy = false,
    priority = 1000,
    config = function()
      require("black-metal").setup({
        theme = "burzum",
      })
      require("black-metal").load()
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "burzum",
    },
  },
}