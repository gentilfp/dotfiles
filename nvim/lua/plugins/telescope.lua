return {
  {
    "nvim-telescope/telescope-live-grep-args.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local lga_actions = require("telescope-live-grep-args.actions")

      telescope.setup({
        extensions = {
          live_grep_args = {
            auto_quoting = false,
            mappings = {
              i = {
                ["<C-k>"] = lga_actions.quote_prompt(),
                ["<A-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
                ["<A-g>"] = lga_actions.quote_prompt({ postfix = " -g " }),
                ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
              },
              n = {
                ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
              },
            },
          },
        },
      })

      telescope.load_extension("live_grep_args")
    end,
    keys = {
      {
        "<leader>/",
        function()
          require("telescope").extensions.live_grep_args.live_grep_args({
            cwd = LazyVim.root.get(),
            prompt_title = "Grep with args (Root Dir)",
          })
        end,
        desc = "Grep with args (Root Dir)",
      },
      {
        "<leader>sg",
        function()
          require("telescope").extensions.live_grep_args.live_grep_args({
            cwd = LazyVim.root.get(),
            prompt_title = "Grep with args (Root Dir)",
          })
        end,
        desc = "Grep with args (Root Dir)",
      },
      {
        "<leader>sG",
        function()
          require("telescope").extensions.live_grep_args.live_grep_args({
            cwd = vim.uv.cwd(),
            prompt_title = "Grep with args (cwd)",
          })
        end,
        desc = "Grep with args (cwd)",
      },
    },
  },
}
