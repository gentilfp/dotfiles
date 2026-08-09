return {
  -- Local, in-editor code review comments for AI-agent workflows.
  -- Exports annotations in a RevDiff-compatible format to the clipboard.
  "eltonsst/postilla.nvim",
  cmd = {
    "PostillaStart",
    "PostillaComment",
    "PostillaList",
    "PostillaDone",
    "PostillaAbort",
    "PostillaEdit",
    "PostillaDelete",
    "PostillaStatus",
  },
  -- <leader>p prefix (README suggests <leader>rc, which collides with Rails controller).
  keys = {
    { "<leader>ps", "<cmd>PostillaStart<cr>", desc = "Postilla: start review" },
    { "<leader>pc", "<cmd>PostillaComment<cr>", mode = { "n", "v" }, desc = "Postilla: add comment" },
    { "<leader>pl", "<cmd>PostillaList<cr>", desc = "Postilla: list comments (quickfix)" },
    { "<leader>pd", "<cmd>PostillaDone<cr>", desc = "Postilla: done (export to clipboard)" },
    { "<leader>px", "<cmd>PostillaAbort<cr>", desc = "Postilla: abort review" },
    { "<leader>pS", "<cmd>PostillaStatus<cr>", desc = "Postilla: session status" },
  },
  opts = {
    context_lines = 5, -- lines of context captured around each reviewed line
  },
  config = function(_, opts)
    require("postilla").setup(opts)
  end,
}
