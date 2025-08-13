return {
  { "tpope/vim-rails" },
  {
    "tpope/vim-bundler",
    ft = { "ruby" },
  },
  {
    "tpope/vim-rake",
    ft = { "ruby" },
  },
  {
    -- Better Rails navigation and commands
    "tpope/vim-projectionist",
    config = function()
      -- Rails projections for better navigation
      vim.g.projectionist_heuristics = {
        ["Gemfile"] = {
          ["app/*.rb"] = { alternate = "spec/{}_spec.rb" },
          ["lib/*.rb"] = { alternate = "spec/{}_spec.rb" },
          ["spec/*_spec.rb"] = { alternate = "app/{}.rb", type = "test" },
        },
      }
    end,
  },
  {
    -- RSpec testing support
    "vim-test/vim-test",
    config = function()
      vim.g["test#strategy"] = "toggleterm"
      vim.g["test#ruby#rspec#options"] = "--format documentation"
      
      -- Key mappings for testing
      vim.keymap.set("n", "<leader>tn", ":TestNearest<CR>", { desc = "Test nearest" })
      vim.keymap.set("n", "<leader>tf", ":TestFile<CR>", { desc = "Test file" })
      vim.keymap.set("n", "<leader>ts", ":TestSuite<CR>", { desc = "Test suite" })
      vim.keymap.set("n", "<leader>tl", ":TestLast<CR>", { desc = "Test last" })
      vim.keymap.set("n", "<leader>tv", ":TestVisit<CR>", { desc = "Test visit" })
    end,
  },
}
