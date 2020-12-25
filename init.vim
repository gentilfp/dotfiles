" Maintainer: fpgentil

" Set python bin location
let g:python_host_prog = '/usr/bin/python'
let g:python3_host_prog = '/usr/bin/python3'

" text width
set textwidth=120

" ignore case
set ignorecase

" smartcase
set smartcase

" Copy/paste from/to clipboard
set clipboard=unnamedplus

" Leader
let mapleader = ","

" Map <Space> to / (search) and Ctrl-<Space> to ? (backwards search)
map <space> /
map <C-space> ?

" Disable highlight when <leader><cr> is pressed
map <silent> <leader><cr> :noh<cr>

" Smart way to move between windows
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

" Close the current buffer
map <leader>bd :Bclose<cr>:tabclose<cr>gT

" Close all the buffers
map <leader>ba :bufdo bd<cr>

map <leader>l :bnext<cr>
map <leader>h :bprevious<cr>

" Useful mappings for managing tabs
map <leader>tn :tabnew<cr>
map <leader>to :tabonly<cr>
map <leader>tc :tabclose<cr>
map <leader>tm :tabmove 
map <leader>t<leader> :tabnext 

" Turn backup off, since most stuff is in SVN, git etc. anyway...
set nobackup
set nowb
set noswapfile

" Use spaces instead of tabs
set expandtab

" Be smart when using tabs ;)
set smarttab

" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4

" Linebreak on 500 characters
set lbr
set tw=500

set ai "Auto indent
set si "Smart indent
set wrap "Wrap lines

" Enable syntax highlighting
syntax enable 

" Fast saving
nmap <leader>w :w!<cr>
nmap <leader>x :x<cr>

" :W sudo saves the file 
" (useful for handling the permission-denied error)
command! W execute 'w !sudo tee % > /dev/null' <bar> edit!

" Turn on the Wild menu
set wildmenu

" Show line numbers
set nu
highlight LineNr ctermfg=grey

"Always show current position
set ruler

" Height of the command bar
set cmdheight=1

" A buffer becomes hidden when it is abandoned
set hid

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases 
set smartcase

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch 

" Don't redraw while executing macros (good performance config)
set lazyredraw 

" For regular expressions turn magic on
set magic

" Show matching brackets when text indicator is over them
set showmatch 
" How many tenths of a second to blink when matching brackets
set mat=2

" No annoying sound on errors
set noerrorbells
set novisualbell
set t_vb=
set tm=500

" ===== PLUGINS =====
" vim-plug
call plug#begin('~/.vim/autoload')

" Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
Plug 'junegunn/vim-easy-align'

" NERDTRee
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
nnoremap <leader>n :NERDTreeToggle<CR>

" Ack (silver_search)
Plug 'mileszs/ack.vim'
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

" CtrlP
Plug 'ctrlpvim/ctrlp.vim'
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'

" Statusline/bar
Plug 'itchyny/lightline.vim'
let g:lightline = { 'colorscheme': 'nord' }

" Comment with gcc
Plug 'tpope/vim-commentary'

" Git
Plug 'tpope/vim-fugitive'
nnoremap <leader>gs :Gstatus<CR>
nnoremap <leader>gc :Gcommit<CR>
nnoremap <leader>gp :Gpush<CR>

" Multi cursor
Plug 'mg979/vim-visual-multi', {'branch': 'master'}

" Languages/Frameworks
Plug 'vim-ruby/vim-ruby'
Plug 'tpope/vim-rails'

" Surround
Plug 'tpope/vim-surround'

" Completion
Plug 'valloric/youcompleteme'

" Tags
Plug 'majutsushi/tagbar'
Plug 'ludovicchabant/vim-gutentags'
let g:gutentags_project_root = ['.git', '.svn', '.root', '.hg', '.project']
nmap <leader>tt :TagbarToggle<CR>

" Always highlight html tags
Plug 'Valloric/MatchTagAlways'

" Modern matchit replacement
Plug 'andymass/vim-matchup'
let g:loaded_matchit = 1

" Fuzzy finder
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
nnoremap <Leader><Leader> :Files<cr>
nnoremap <Leader>b :Buffers<cr>
nnoremap <Leader>f :Ag <C-R><C-W><cr>
vnoremap <Leader>f y:Ag <C-R>"<cr>
nnoremap <C-F> :Ag<Space>"

" Initialize plugin system
call plug#end()