return {
  "LintaoAmons/scratch.nvim",
  dependencies = { "folke/snacks.nvim" },
  cmd = { "Scratch", "ScratchWithName", "ScratchOpen" },
  keys = {
    { "<leader>sn", "<cmd>Scratch<cr>", desc = "New scratch (pick filetype)" },
    { "<leader>sN", "<cmd>ScratchWithName<cr>", desc = "New named scratch" },
    { "<leader>so", "<cmd>ScratchOpen<cr>", desc = "Open scratch (find + grep)" },
  },
  opts = {
    -- Default cache dir: stdpath("cache")/scratch.nvim -- disposable, not backed up.
    file_picker = "snacks", -- match the picker used everywhere else in this config
    filetypes = { "md", "rb", "lua", "js", "sh", "json" },
  },
}
