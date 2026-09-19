local function copy_url()
  require("gitlinker").get_buf_range_url(vim.fn.mode(1) == "n" and "n" or "v", {
    action_callback = require("gitlinker.actions").copy_to_clipboard,
  })
end

return {
  "ruifm/gitlinker.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    opts = {
      action_callback = function(url)
        require("gitlinker.actions").open_in_browser(url)
      end,
    },
  },
  keys = {
    { "<leader>gy", "<cmd>GitLink<cr>", mode = { "n", "v" }, desc = "Open Git link in browser" },
    { "<leader>gY", copy_url, mode = { "n", "v" }, desc = "Copy Git link" },
  },
}