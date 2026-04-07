return {
  {
    "lewis6991/gitsigns.nvim",
    config = function(_, opts)
      require("gitsigns").setup(opts)
      local function set_blame_highlight()
        local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
        vim.api.nvim_set_hl(0, "GitSignsCurrentLineBlame", {
          fg = comment.fg,
          bg = comment.bg,
          italic = comment.italic,
          bold = false,
        })
      end

      local group = vim.api.nvim_create_augroup("custom_gitsigns_highlights", { clear = true })
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = set_blame_highlight,
      })

      set_blame_highlight()
    end,
    opts = {
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 100,
      },
      current_line_blame_formatter = "     <author>, <author_time:%Y-%m-%d> - <summary>",
    },
  },
}
