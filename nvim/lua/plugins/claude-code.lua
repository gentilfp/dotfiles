return {
  "greggh/claude-code.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude conversation" },
  },
  opts = {
    window = {
      position = "vertical",
      width = 80,
    },
  },
}
