" This is a vimrc comment

" Load pathogen plugin - for easier managment of other plugins
"execute pathogen#infect()
"filetype plugin indent on

" Set Leader character
let mapleader=","

" Vi compatibility is not needed
set nocompatible

" Disable modelines to prevent security exploits
set modelines=0

" Show line numbers
set number

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases
set smartcase

" Highlight search results
set hlsearch

" Incremental search
set incsearch

" Show matching brackets when text indicator is over them
set showmatch

" Hide highlight after searching
nnoremap <leader><space> :noh<CR>

" Use tab for finding matching parentheses
nnoremap <tab> %
vnoremap <tab> %

" Set character encoding
set encoding=utf-8

" Set number of lines always visible around cursor
set scrolloff=3

" Keep indent of current line when starting new line
set autoindent

" Show current mode
set showmode

" Show command in the last line of the sceen
set showcmd

" Do not prompt for writing modified file when opening new file
set hidden

" Show command-line completion menu
set wildmenu

" Set command-line completion mode
set wildmode=list:longest

" Highlight the screen line of the cursor
set cursorline

" Allow for more frequent redrawing
set ttyfast

" Display cursor line and column position
set ruler

" Always display status line
set laststatus=2

" Enable syntax highlighting
syntax enable

" Use spaces instead of tabs
set expandtab

" Show white characters
set nolist
set listchars=tab:▸\ ,eol:¬

" Toggling of white characters visibility
nmap <leader>l :set list!<CR>

" Remove trailing whitespaces from the current file
nnoremap <leader>w :%s/\s\+$//<CR>:let @/=''<CR>

" Open new vertical window and go there
nnoremap <leader>v <C-w>v<C-w>l

" Open new horizontal window and go there
nnoremap <leader>s <C-w>s<C-w>j

" Simplify window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Disable arrow keys navigation
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>

inoremap <expr> <Esc>       pumvisible() ? "\<C-e>" : "\<Esc>"
inoremap <expr> <CR>        pumvisible() ? "\<C-y>" : "\<CR>"
inoremap <expr> j           pumvisible() ? "\<C-n>" : "j"
inoremap <expr> k           pumvisible() ? "\<C-p>" : "k"
inoremap <expr> <PageDown>  pumvisible() ? "\<PageDown>\<C-p>\<C-n>" : "\<PageDown>"
inoremap <expr> <PageUp>    pumvisible() ? "\<PageUp>\<C-p>\<C-n>" : "\<PageUp>"

" Move by screen line instead of file line
nnoremap j gj
nnoremap k gk

" Remap F1 (help key) to ESC
inoremap <F1> <ESC>
nnoremap <F1> <ESC>
vnoremap <F1> <ESC>

" Tab width
set tabstop=4
set shiftwidth=4
set softtabstop=4

" Set color scheme
"colorscheme solarized

" Set dark backgound
set background=dark

" Mark 80th column
set colorcolumn=80

" Set tags file location searching pattern
set tags=tags;

" Map NERDTree toggling
"map <F5> :NERDTreeToggle<CR>
"map <F6> :NERDTreeFocus<CR>

" Map Tagbar to F8
"nmap <F8> :TagbarToggle<CR>

" Do not wrap long lines
set nowrap

" Do not continue comments on new lines
set formatoptions-=cro

