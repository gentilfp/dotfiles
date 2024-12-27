return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("gitsigns").setup({
        current_line_blame = true, -- Exibe o blame inline por padrão
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = "eol", -- Exibe no final da linha
          delay = 100, -- Atraso antes de exibir
        },
        current_line_blame_formatter = string.rep(" ", 5) .. "<author>, <author_time:%Y-%m-%d> - <summary>",
      })
      -- Ativa permanentemente o blame inline
      require("gitsigns").toggle_current_line_blame(true)
    end,
  },
}
