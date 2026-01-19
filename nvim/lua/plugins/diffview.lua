return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Git diff" },
    { "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Close git diff" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File git history" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Branch git history" },
  },
  opts = {
    enhanced_diff_hl = true,
    view = {
      merge_tool = {
        layout = "diff3_mixed",
      },
    },
  },
}
