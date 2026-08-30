-- markview.nvim replaces LazyVim's render-markdown.nvim for in-buffer rendering.
-- Everything markview does NOT do is left to the lang.markdown extra:
-- marksman LSP, markdownlint-cli2/markdown-toc/prettier, and markdown-preview.nvim (<leader>cp).
return {
  {
    "OXY2DEV/markview.nvim",
    -- Upstream recommends lazy = false; the plugin does its own filetype gating.
    lazy = false,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    keys = {
      -- Replaces the <leader>um toggle the render-markdown extra used to provide.
      { "<leader>um", "<cmd>Markview Toggle<cr>", desc = "Toggle Markview" },
      { "<leader>uM", "<cmd>Markview splitToggle<cr>", desc = "Toggle Markview splitview" },
    },
    opts = {
      preview = {
        -- Defaults also cover quarto/rmd/typst/asciidoc; keep those.
        hybrid_modes = { "n" }, -- show raw text on the line the cursor is on
      },
    },
  },

  -- Superseded by markview.nvim.
  { "MeanderingProgrammer/render-markdown.nvim", enabled = false },
}
