return {
  -- add dracula
  { "Mofiqul/dracula.nvim" },

  -- { "nxstynate/oneDarkPro.nvim", priority = 1000 },

  -- Configure LazyVim to load dracula
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "dracula",
    },
  },
}
