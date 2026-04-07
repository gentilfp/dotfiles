return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = false, -- Disable inline diagnostics
        signs = true,
        underline = true,
        update_in_insert = false,
        float = {
          border = "rounded",
          source = true,
        },
      },
      servers = {
        ruby_lsp = {
          mason = false,
          cmd = { "mise", "exec", "--", "ruby-lsp" },
          filetypes = { "ruby", "eruby" },
          root_markers = { "Gemfile", ".git" },
          init_options = { formatter = "auto" },
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
