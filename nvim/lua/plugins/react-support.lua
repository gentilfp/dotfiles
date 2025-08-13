return {
  -- React/TypeScript development
  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    config = true,
  },
  {
    "maxmellon/vim-jsx-pretty",
    ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  },
  {
    -- Emmet for HTML/JSX
    "mattn/emmet-vim",
    ft = { "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact", "eruby" },
    config = function()
      vim.g.user_emmet_leader_key = "<C-z>"
      vim.g.user_emmet_settings = {
        javascript = {
          extends = "jsx",
        },
        typescript = {
          extends = "tsx",
        },
      }
    end,
  },
  {
    -- Better syntax highlighting and folding
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "ruby",
        "typescript",
        "tsx",
        "javascript",
        "json",
        "css",
        "scss",
        "html",
        "yaml",
        "bash",
      })
    end,
  },
}