return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Git diff" },
    { "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Close git diff" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File git history" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Branch git history" },
    {
      "<leader>gr",
      function()
        -- PR-style self-review: diff the branch against the merge-base of the
        -- repo's default branch (origin/HEAD if set, else main/master).
        local base = vim.fn.systemlist("git symbolic-ref --quiet --short refs/remotes/origin/HEAD")[1]
        if vim.v.shell_error ~= 0 or not base or base == "" then
          base = nil
          for _, b in ipairs({ "main", "master" }) do
            vim.fn.system("git rev-parse --verify --quiet " .. b)
            if vim.v.shell_error == 0 then
              base = b
              break
            end
          end
        end
        if not base then
          vim.notify("diffview: no default branch found (main/master)", vim.log.levels.WARN)
          return
        end
        vim.cmd("DiffviewOpen " .. base .. "...HEAD")
      end,
      desc = "Review branch vs default branch",
    },
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
