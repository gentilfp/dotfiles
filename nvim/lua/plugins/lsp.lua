return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = false,  -- Disable inline diagnostics
        signs = true,
        underline = true,
        update_in_insert = false,
        float = {
          border = "rounded",
          source = true,
        },
      },
      servers = {
        -- Ruby LSP - uses sensible defaults
        rubylsp = {
          cmd = { "mise", "exec", "--", "ruby-lsp" },
          mason = false,
        },
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
    "mason-org/mason-lspconfig.nvim",
    opts = {
      exclude = { "ruby_lsp" },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "typescript-language-server",
        "html-lsp",
        "css-lsp",
        "tailwindcss-language-server",
      },
    },
  },
}
