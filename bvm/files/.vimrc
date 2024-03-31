" SOURCE: dotfiles/bvm
set nocp " do this first
set viminfo=%,'50,\"100,:100,n~/.cache/viminfo
set nobackup nodigraph
set ruler showcmd showmatch showmode vb wmnu
set noeb

colorscheme desert
let c_space_errors = 1
syntax on
set hlsearch

set sw=2 ts=4 et

set pastetoggle=<F5>

set cf " enable error files and error jumping

nnoremap <C-N> :next<Enter>
nnoremap <C-P> :prev<Enter>

if has("autocmd")
  " When editing a file, always jump to the last cursor position
  autocmd BufReadPost *
  \ if line("'\"") > 0 && line ("'\"") <= line("$") |
  \   exe "normal g'\"" |
  \ endif
endif

set background=light
