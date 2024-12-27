return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
    config = function()
      require("neo-tree").setup({
        window = {
          position = "right", -- Posiciona a tree no lado direito
          width = 45, -- Largura da tree
        },
        filesystem = {
          follow_current_file = {
            enabled = true, -- Sincroniza com o buffer atual
          },
          hijack_netrw_behavior = "open_current", -- Garante que abra o diretório correto
          use_libuv_file_watcher = true, -- Monitora mudanças no sistema de arquivos
        },
        default_component_configs = {
          indent = {
            with_markers = true, -- Mostra marcadores de indentação
          },
        },
        event_handlers = {
          {
            event = "neo_tree_window_after_open",
            handler = function()
              vim.cmd("silent! NeoTreeReveal") -- Garante que o arquivo atual seja revelado na tree
            end,
          },
        },
      })
    end,
  },
}
