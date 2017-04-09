set nocompatible
filetype off

" set the runtime path to include Vundle and initialize

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required

Plugin 'VundleVim/Vundle.vim'

Plugin 'jelera/vim-javascript-syntax'

Plugin 'othree/javascript-libraries-syntax'

Plugin 'kchmck/vim-coffee-script'

call vundle#end()            " required
execute pathogen#infect()
filetype plugin indent on    " required

" Enable syntax highlighting
syntax enable 

" 1 tab == 2 spaces
set shiftwidth=2
set tabstop=2

" Show line numbers
set number

" Show “invisible” characters
set lcs=tab:▸\ ,trail:·,eol:¬,nbsp:_
set list

" disable arrow keys
inoremap  <Up>     <NOP>
inoremap  <Down>   <NOP>
inoremap  <Left>   <NOP>
inoremap  <Right>  <NOP>
noremap   <Up>     <NOP>
noremap   <Down>   <NOP>
noremap   <Left>   <NOP>
noremap   <Right>  <NOP>

" move lines up and down with alt j/k
nnoremap ∆ :m .+1<CR>==
nnoremap ˚ :m .-2<CR>==
inoremap ∆ <Esc>:m .+1<CR>==gi
inoremap ˚ <Esc>:m .-2<CR>==gi
vnoremap ∆ :m '>+1<CR>gv=gv
vnoremap ˚ :m '<-2<CR>gv=gv


" ctrl N to toggle NERDTree
map <C-N> :NERDTreeToggle<CR>
