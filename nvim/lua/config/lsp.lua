return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      document_highlight = { enabled = false },
      servers = {
        -- Ruby LSP for Rails development
        rubylsp = {
          enabled = true,
          cmd = { "ruby-lsp" },
          filetypes = { "ruby" },
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern("Gemfile", ".git")(fname)
          end,
          init_options = {
            enabledFeatures = {
              "codeActions",
              "codeLens",
              "completion",
              "definition",
              "diagnostics",
              "documentHighlight",
              "documentLink",
              "documentSymbol",
              "foldingRange",
              "formatting",
              "hover",
              "inlayHint",
              "onTypeFormatting",
              "selectionRange",
              "semanticHighlighting",
              "signatureHelp",
              "typeHierarchy",
              "workspaceSymbol",
            },
          },
          settings = {
            rubylsp = {
              featuresConfiguration = {
                inlayHint = {
                  enableAll = true,
                },
              },
            },
          },
        },
        -- TypeScript for React projects
        ts_ls = {
          enabled = true,
          filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
        },
        -- HTML/CSS for ERB templates
        html = { filetypes = { "html", "eruby" } },
        cssls = {},
        tailwindcss = {
          filetypes = { "html", "css", "scss", "eruby", "javascript", "javascriptreact", "typescript", "typescriptreact" },
        },
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "ruby-lsp",
        "typescript-language-server",
        "html-lsp",
        "css-lsp",
        "tailwindcss-language-server",
        "rubocop",
        "prettier",
        "standardrb",
      },
    },
  },
}
