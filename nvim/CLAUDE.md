# Vim Configuration Guide for Rails Development

## Overview
This Neovim configuration is optimized for Rails development with some React support. It includes Ruby LSP for proper navigation, Rails-specific plugins, and VSCode-like keybindings. Built on LazyVim.

## Key Features

### Ruby LSP & Navigation
- **Ruby LSP** configured for go-to-definition, hover, and diagnostics
- **Mason** automatically installs: ruby-lsp, typescript-language-server, html-lsp, css-lsp, tailwindcss
- Press `gd` to go to definition
- Press `gr` to see references
- Press `K` for hover documentation

### Rails Navigation
- **`<leader>ra`** - Switch between class and spec file
- **`<leader>rm`** - Go to model
- **`<leader>rv`** - Go to view
- **`<leader>rc`** - Go to controller
- **`<leader>rr`** - Go to related file

### Testing (RSpec)
- **`<leader>tn`** - Run nearest test
- **`<leader>tf`** - Run current test file
- **`<leader>ts`** - Run entire test suite
- **`<leader>tl`** - Run last test
- **`<leader>tv`** - Visit test file

### Rails Commands
- **`<leader>Rs`** - Start Rails server in terminal
- **`<leader>Rc`** - Open Rails console in terminal
- **`<leader>Rd`** - Run database migrations

### Terminal Integration
- **`Ctrl+\`** - Toggle terminal
- **`<leader>Tf`** - Float terminal
- **`<leader>Th`** - Horizontal terminal
- **`<leader>Tv`** - Vertical terminal

### File Operations
- **`<leader>w`** - Save file
- **`<leader>q`** - Quit
- **`<leader>x`** - Save and quit
- **`Tab`** / **`Shift+Tab`** - Navigate between buffers
- **`<leader>cp`** - Copy relative file path to clipboard

### Window Navigation
- **`Ctrl+h/j/k/l`** - Move between windows (left/down/up/right)
- **`<C-w>v`** - Vertical split
- **`<C-w>s`** - Horizontal split
- **`<C-w>o`** - Close other windows

### Search & Replace (VS Code-like)
- **`<leader>sg`** - Live grep (search in files)
- **`<leader>sG`** - Grep with args (include/exclude patterns)
- **`<leader>sr`** - Search & Replace with Spectre
- **`<leader>sR`** - Replace word under cursor
- **`<leader>sp`** - Replace in current file

#### Grep with args syntax
```
"search term" -g **/*.rb        # only ruby files
"search term" -g **/app/**      # only in app folder
"search term" -g !**/spec/**    # exclude spec folder
```

### Git Integration
- **`<leader>gg`** - Open Lazygit
- **`<leader>gd`** - Open git diff view (Diffview)
- **`<leader>gD`** - Close git diff view
- **`<leader>gh`** - Current file git history
- **`<leader>gH`** - Branch git history
- **`<leader>gp`** - Find PR for current line's commit
- **`<leader>gt`** - Find PRs touching current file

### Claude Code Integration
- **`<leader>ac`** - Toggle Claude Code
- **`<leader>aC`** - Continue Claude conversation

## Installed Plugins

### Core Rails Support
- `vim-rails` - Rails navigation and commands
- `vim-bundler` - Bundler integration
- `vim-rake` - Rake task support
- `vim-projectionist` - Project navigation
- `vim-test` - Test runner integration

### React/TypeScript Support
- `nvim-ts-autotag` - Auto-close HTML/JSX tags
- `vim-jsx-pretty` - JSX syntax highlighting
- `emmet-vim` - HTML/CSS abbreviations (Ctrl+z trigger)

### Search & Navigation
- `telescope.nvim` - Fuzzy finder (LazyVim default)
- `telescope-live-grep-args` - Grep with include/exclude filters
- `nvim-spectre` - Search & replace across files

### Git
- `lazygit.nvim` - Git UI
- `gitsigns.nvim` - Git signs in gutter
- `diffview.nvim` - Git diff viewer

### AI
- `claude-code.nvim` - Claude Code integration

### LSP & Development
- `nvim-lspconfig` - Language server configuration
- `mason.nvim` - LSP installer
- `toggleterm.nvim` - Terminal integration
- `neo-tree.nvim` - File explorer

## Configuration Details

### Diagnostics
- Inline virtual text is **disabled** (less visual noise)
- Signs show in the gutter (icons by line numbers)
- Underlines still highlight problematic code
- **`gl`** - Show diagnostics for current line in floating window
- **`<leader>cd`** - Show diagnostics for current line
- **`[d`** / **`]d`** - Jump to previous/next diagnostic
- Auto-popup when cursor holds on a line (~250ms)

### Visual Guides
- 120-character vertical line (colorcolumn)
- Relative line numbers enabled
- Cursor line highlighted

### Editor Behavior
- Auto-format on save is **disabled**
- System clipboard integration enabled
- Persistent undo across sessions
- 2-space indentation (tabs as spaces)

## Getting Started

1. **First-time setup**: Open Neovim and let Lazy install plugins, then Mason installs LSPs
2. **Ruby projects**: Navigate to a Rails project - Ruby LSP should work automatically
3. **Navigation**: Use `gd` to jump to definitions, `<leader>ra` to switch between files
4. **Testing**: Use `<leader>tn` to run the test under cursor
5. **Terminal**: Press `Ctrl+\` to open a terminal for Rails commands
6. **Search**: Use `<leader>sG` for VS Code-like search with filters

## Tips for Vim Beginners

- **Leader key** is `Space` (LazyVim default)
- **Which-key** shows available shortcuts when you press `<leader>` and wait
- **Normal mode** is for navigation, **Insert mode** for typing
- Press `Esc` to return to normal mode
- Use `<leader>ff` to find files (like CMD+P in VS Code)
- Use `<leader>sg` to search in files (like CMD+SHIFT+F in VS Code)

## Troubleshooting

- **Ruby LSP not working?** Make sure you have `ruby-lsp` gem installed: `gem install ruby-lsp`
- **Tests not running?** Ensure you're in a Rails project with RSpec configured
- **Want to see available commands?** Press `<leader>` and wait for which-key popup
- **Neovim crashing?** Check logs at `~/.local/state/nvim/log`
- **Plugin issues?** Try `:Lazy sync` to update plugins

## Logs & Debugging

```bash
# Neovim log
~/.local/state/nvim/log

# Start without config (to test if config is the issue)
nvim --clean

# Check startup time
nvim --startuptime /tmp/startup.log
```
