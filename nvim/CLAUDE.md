# Vim Configuration Guide for Rails Development

## Overview
This Neovim configuration is optimized for Rails development with some React support. It includes Ruby LSP for proper navigation, Rails-specific plugins, and VSCode-like keybindings.

## Key Features

### Ruby LSP & Navigation
- **Ruby LSP** configured for go-to-definition, hover, and diagnostics
- **Mason** automatically installs: ruby-lsp, rubocop, standardrb
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

### Window Navigation
- **`Ctrl+h/j/k/l`** - Move between windows (left/down/up/right)

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

### LSP & Development
- `nvim-lspconfig` - Language server configuration
- `mason.nvim` - LSP installer
- `toggleterm.nvim` - Terminal integration

## Getting Started

1. **First-time setup**: Open Neovim and let Mason install the language servers
2. **Ruby projects**: Navigate to a Rails project - Ruby LSP should work automatically
3. **Navigation**: Use `gd` to jump to method definitions, `<leader>ra` to switch between files
4. **Testing**: Use `<leader>tn` to run the test under cursor
5. **Terminal**: Press `Ctrl+\` to open a terminal for Rails commands

## Tips for Vim Beginners

- **Leader key** is `Space` (LazyVim default)
- **Which-key** shows available shortcuts when you press `<leader>`
- **Normal mode** is for navigation, **Insert mode** for typing
- Press `Esc` or `jk` to return to normal mode
- Practice one new command per day to build muscle memory

## Troubleshooting

- **Ruby LSP not working?** Make sure you have `ruby-lsp` gem installed: `gem install ruby-lsp`
- **Tests not running?** Ensure you're in a Rails project with RSpec configured
- **Want to see available commands?** Press `<leader>` and wait for which-key popup

## Future Improvements
- Consider adding `vim-fugitive` for better Git integration
- Add `nvim-dap` for debugging support
- Configure `null-ls` for additional linting/formatting