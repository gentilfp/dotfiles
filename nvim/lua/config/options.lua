-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable format-on-save from LazyVim/Conform
vim.g.autoformat = false

-- Line numbers
vim.o.number = true
vim.o.relativenumber = true

-- VS Code-like behavior
vim.o.scrolloff = 8              -- Keep 8 lines above/below cursor
vim.o.sidescrolloff = 8          -- Keep 8 columns left/right of cursor
vim.o.wrap = false               -- Don't wrap lines
vim.o.cursorline = true          -- Highlight current line
vim.o.ignorecase = true          -- Case insensitive search
vim.o.smartcase = true           -- Unless uppercase is used
vim.o.clipboard = "unnamedplus"  -- Use system clipboard
vim.o.undofile = true            -- Persistent undo
vim.o.splitright = true          -- Split windows to the right
vim.o.splitbelow = true          -- Split windows below

-- Better editing experience
vim.o.tabstop = 2                -- Tab width
vim.o.shiftwidth = 2             -- Indent width
vim.o.expandtab = true           -- Use spaces instead of tabs
vim.o.smartindent = true         -- Smart auto-indenting

-- Performance
vim.o.updatetime = 250           -- Faster completion
vim.o.timeoutlen = 300           -- Faster which-key popup

-- Visual guides
vim.o.colorcolumn = "120"        -- Show vertical line at 120 characters

-- Disable spelling globally
vim.o.spell = false

-- Diagnostics config is in autocmds.lua (needs to run after LazyVim)
