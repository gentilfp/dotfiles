return {
  "NickvanDyke/opencode.nvim",
  dependencies = {
    "folke/snacks.nvim",
  },
  keys = {
    { "<leader>ao", function() require("opencode").toggle() end, desc = "Toggle OpenCode" },
    { "<leader>aO", function() require("opencode").ask("@this: ", { submit = true }) end, desc = "Ask OpenCode", mode = { "n", "x" } },
    { "<leader>as", function() require("opencode").select() end, desc = "OpenCode select action", mode = { "n", "x" } },
  },
  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      -- Your configuration here
    }

    -- Required for opts.events.reload
    vim.o.autoread = true
  end,
}
