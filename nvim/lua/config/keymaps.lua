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

-- Pull request references
vim.keymap.set("n", "<leader>gp", function()
  local filename = vim.fn.expand("%")
  local line_number = vim.fn.line(".")

  local blame_cmd = string.format("git blame -L %d,%d --porcelain %s", line_number, line_number, filename)
  local commit_hash = vim.fn.system(blame_cmd):match("^(%w+)")
  local output =
    vim.fn.system("gh pr list --state=all --search " .. commit_hash .. " --json number,title,author,createdAt,url")

  -- Parse JSON and get first PR
  local success, prs = pcall(vim.fn.json_decode, output)

  if not success or not prs or #prs == 0 then
    print("No PRs found for this commit")
    return
  end

  local pr = prs[1] -- Take only the first PR

  -- Format the output nicely
  local formatted_lines = {
    "PR #" .. pr.number .. ": " .. pr.title,
    "",
    "Author: " .. pr.author.name .. " (@" .. pr.author.login .. ")",
    "Created: " .. pr.createdAt:sub(1, 10), -- Just the date part
    "",
    "URL: " .. pr.url,
  }

  -- Create floating window with formatted output
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, formatted_lines)

  -- Make the buffer modifiable so we can copy the URL easily
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  local width = 80
  local height = #formatted_lines + 2
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    border = "rounded",
    title = " PR for commit " .. commit_hash:sub(1, 8) .. " ",
  }

  vim.api.nvim_open_win(buf, true, opts)
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf })
  vim.keymap.set("n", "<CR>", function()
    vim.fn.system("open " .. pr.url) -- On macOS, use "xdg-open" on Linux
  end, { buffer = buf, desc = "Open PR in browser" })
end, { desc = "Find PR for current line's commit" })

vim.keymap.set("n", "<leader>gt", function()
  local filename = vim.fn.expand("%")

  -- Search PRs touching the current file
  local file_output =
    vim.fn.system("gh pr list --state=all --search " .. filename .. " --json number,title,author,createdAt,url")

  -- Parse and format file PRs
  local success, file_prs = pcall(vim.fn.json_decode, file_output)

  if not success or not file_prs or #file_prs == 0 then
    print("No PRs found for this file")
    return
  end

  local formatted_lines = {
    "PRs TOUCHING THIS FILE:",
    "",
  }

  for i, pr in ipairs(file_prs) do
    if i <= 10 then -- Limit to 10 PRs
      local pr_lines = {
        "PR #" .. pr.number .. ": " .. pr.title,
        "Author: " .. pr.author.name .. " (@" .. pr.author.login .. ")",
        "Created: " .. pr.createdAt:sub(1, 10),
        "URL: " .. pr.url,
      }
      vim.list_extend(formatted_lines, pr_lines)
      if i < #file_prs and i < 10 then
        table.insert(formatted_lines, "") -- Empty line between PRs
      end
    end
  end

  -- Create floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, formatted_lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  local width = 90
  local height = math.min(#formatted_lines + 2, 25)
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    border = "rounded",
    title = " PRs for " .. vim.fn.fnamemodify(filename, ":t") .. " ",
  }

  vim.api.nvim_open_win(buf, true, opts)
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf })
end, { desc = "Find PRs touching current file" })
