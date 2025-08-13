-- Copy relative path
vim.keymap.set("n", "<leader>cp", function()
  local relpath = vim.fn.expand("%:~:.")
  vim.fn.setreg("+", relpath) -- Set it to the clipboard
  vim.notify("Copied relative path: " .. relpath)
end, { noremap = true, silent = true, desc = "Copy Relative File Path to Clipboard" })

-- Set tabs to go forward and backward in buffers
vim.keymap.set("n", "<Tab>", ":bnext<CR>", { noremap = true, silent = true, desc = "Próximo buffer" })
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", { noremap = true, silent = true, desc = "Buffer anterior" })

-- VSCode-like keymaps for Rails development
-- Go to definition (should work with Ruby LSP now)
vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { desc = "Go to definition" })
vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", { desc = "Go to references" })
vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", { desc = "Hover documentation" })

-- Rails-specific navigation (using vim-rails)
vim.keymap.set("n", "<leader>ra", ":A<CR>", { desc = "Rails alternate (spec <-> class)" })
vim.keymap.set("n", "<leader>rr", ":R<CR>", { desc = "Rails related file" })
vim.keymap.set("n", "<leader>rm", ":Emodel<CR>", { desc = "Rails model" })
vim.keymap.set("n", "<leader>rv", ":Eview<CR>", { desc = "Rails view" })
vim.keymap.set("n", "<leader>rc", ":Econtroller<CR>", { desc = "Rails controller" })

-- Quick file operations
vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quit" })
vim.keymap.set("n", "<leader>x", ":x<CR>", { desc = "Save and quit" })

-- Better window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Rails console and server shortcuts
vim.keymap.set("n", "<leader>Rs", ":TermExec cmd='rails server'<CR>", { desc = "Start Rails server" })
vim.keymap.set("n", "<leader>Rc", ":TermExec cmd='rails console'<CR>", { desc = "Start Rails console" })
vim.keymap.set("n", "<leader>Rd", ":TermExec cmd='rails db:migrate'<CR>", { desc = "Run migrations" })
