return {
  "akinsho/bufferline.nvim",
  opts = {
    options = {
      -- Middle-click a tab to close its buffer (VS Code style).
      -- Uses Snacks.bufdelete so the window layout is preserved.
      middle_mouse_command = function(n)
        Snacks.bufdelete(n)
      end,
    },
  },
}
