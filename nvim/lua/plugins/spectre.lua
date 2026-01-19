return {
  "nvim-pack/nvim-spectre",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>sr", function() require("spectre").open() end, desc = "Search & Replace (Spectre)" },
    { "<leader>sR", function() require("spectre").open_visual({ select_word = true }) end, desc = "Replace word under cursor" },
    { "<leader>sp", function() require("spectre").open_file_search({ select_word = true }) end, desc = "Replace in current file" },
  },
  opts = {
    highlight = {
      ui = "String",
      search = "DiffChange",
      replace = "DiffDelete",
    },
  },
}
