return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Ruby LSP - uses sensible defaults
        rubylsp = {},
        -- TypeScript/JavaScript for React
        ts_ls = {},
        -- HTML/CSS for ERB templates
        html = { filetypes = { "html", "eruby" } },
        cssls = {},
        -- Tailwind
        tailwindcss = {},
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "ruby-lsp",
        "typescript-language-server",
        "html-lsp",
        "css-lsp",
        "tailwindcss-language-server",
      },
    },
  },
}
