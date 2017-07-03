
set nocp " do this first


set viminfo=%,'50,\"100,:100,n~/.cache/viminfo
set nobackup nodigraph
" ek hidden
set ruler showcmd showmatch showmode vb wmnu
set noeb
set fo=cqrt ls=2

colorscheme desert 
let c_space_errors = 1
syntax on
set hlsearch
" tags=tags,./tags
" filetype plugin indent on

set sw=2 ts=4 et

set pastetoggle=<F5>

set cf " enable error files and error jumping

nnoremap <C-N> :next<Enter>
nnoremap <C-P> :prev<Enter>

" Only do this part when compiled with support for autocommands
if has("autocmd")
  " When editing a file, always jump to the last cursor position
  autocmd BufReadPost *
  \ if line("'\"") > 0 && line ("'\"") <= line("$") |
  \   exe "normal g'\"" |
  \ endif
endif

set background=light

imap jts<cr> <C-R>=strftime("%F")<cr> [zeha]<cr>-----------------<cr>

