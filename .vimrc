set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" to install plugins
Plugin 'VundleVim/Vundle.vim'

" general coding
Plugin 'ervandew/supertab'
Plugin 'Valloric/YouCompleteMe'
"Plugin 'tpope/vim-surround'
"Plugin 'scrooloose/nerdcommenter'
Plugin 'editorconfig/editorconfig-vim'
Plugin 'SirVer/ultisnips'
Plugin 'honza/vim-snippets'

"Plugin 'junegunn/goyo.vim'
"Plugin 'wikitopian/hardmode'
"Plugin 'takac/vim-hardtime'

" front end
"Plugin 'maksimr/vim-jsbeautify'
"Plugin 'mattn/emmet-vim'
"Plugin 'gko/vim-coloresque'
"Plugin 'jelera/vim-javascript-syntax'
"Plugin 'kchmck/vim-coffee-script'
"Plugin 'mxw/vim-jsx'
"Plugin 'tpope/vim-liquid'
"Plugin 'chase/vim-ansible-yaml'

" wordpress
"Plugin 'shawncplus/phpcomplete.vim'
"Plugin 'dsawardekar/wordpress.vim'

" themes
Plugin 'flazz/vim-colorschemes'
" Plugin 'grigio/vim-sublime'

call vundle#end()            " required
execute pathogen#infect()
filetype plugin indent on    " required

" 1 tab == 2 spaces
set tabstop=2
set shiftwidth=2
set expandtab

" theme
syntax enable
set background=dark
colorscheme monokai
" colorscheme solas
" colorscheme distinguished

" show empty characters
" :set syntax=whitespace
" :set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<
" :set list

" Show line numbers
set number
set relativenumber
set guifont=Meslo\ LG\ M\Regular\ for\ Powerline:h14

" cursor and line
set cursorline
set guicursor+=a:blinkon0
set guicursor=a:hor7-Cursor
let &t_SI .= "\<Esc>[4 q"

" Show “invisible” characters
set lcs=tab:▸\ ,trail:·,eol:¬,nbsp:_
set list

nnoremap <Leader>z :Goyo<CR>i<Esc>`^

" make js beautiful
map <C-B> :call JsBeautify()<cr>
" disable arrow keys
" inoremap  <Up>     <NOP>
" inoremap  <Down>   <NOP>
" inoremap  <Left>   <NOP>
" inoremap  <Right>  <NOP>
" noremap   <Right>  <NOP>
" noremap   <Up>     <NOP>
" noremap   <Down>   <NOP>
" noremap   <Left>   <NOP>

" move lines up and down with alt j/k
nnoremap ∆ :m .+1<CR>==
nnoremap ˚ :m .-2<CR>==
inoremap ∆ <Esc>:m .+1<CR>==gi
inoremap ˚ <Esc>:m .-2<CR>==gi
vnoremap ∆ :m '>+1<CR>gv=gv
vnoremap ˚ :m '<-2<CR>gv=gv

" auto close parens
:inoremap ( ()<Esc>i
:inoremap [ []<Esc>i
:inoremap { {}<Esc>i

" make YouCompleteMe compatible with UltiSnips (using supertab)
let g:ycm_key_list_select_completion = ['<C-n>', '<Down>']
let g:ycm_key_list_previous_completion = ['<C-p>', '<Up>']
let g:SuperTabDefaultCompletionType = '<C-n>'

" better key bindings for UltiSnipsExpandTrigger
let g:UltiSnipsExpandTrigger = "<tab>"
let g:UltiSnipsJumpForwardTrigger = "<tab>"
let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"
let g:UltiSnipsEditSplit="vertical"
set runtimepath+=~/.vim/ultisnips_rep

" load plugins with Pathogen
execute pathogen#infect()
call pathogen#helptags()

" insert a new line in normal mode
map <Enter> o<ESC>
map <S-Enter> O<ESC>

" toggle nerdtree with CTRL N
map <C-N> :NERDTreeToggle<CR>
" show dot files
let NERDTreeShowHidden=1
let NERDTreeIgnore=['\.swp$', '\.DS_Store']

" toggle comments with CTRL /
map <C-_> <leader>c<Space>
map <C-/> <leader>c<Space>
" toggle comments with ALT /
map <A-/> <leader>c<Space>
map <A-_> <leader>c<Space>
map <A-_> <leader>c<Space>
" toggle comments with CMND /
map <D-/> <leader>c<Space>
map <D-_> <leader>c<Space>
" custom comment schema
let g:NERDCustomDelimiters = { 'javascript': { 'left': '// ','right': '' } }

" autoindent with enter on ctrl enter
imap <C-Return> <CR><CR><C-o>k<Tab>

" runtimepath for fizzy search
set runtimepath^=~/.vim/bundle/ctrlp.vim
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git'

"make < > shifts keep selection
vnoremap < <gv
vnoremap > >gv

" two spaces indentation for js files
autocmd Filetype javascript setlocal ts=2 sts=2 sw=2

" ctrl j/k/l/h shortcutes to navigate between multiple windows
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
" ctrl e to maximaze current window
nnoremap <C-E> <C-W><C-_>
" ctrl d to make all windows equal size
nnoremap <C-D> <C-W><C-=>
" ctrl s to split window horizontally
nnoremap <C-S> <C-W>S
" save with leader s
noremap <d-S> :update<CR>
" folding
set foldmethod=syntax
set foldlevelstart=10

" let javaScript_fold=1
"
set linebreak

" always keep 10 lines above and below the cursor
set scrolloff=10

" highlight column 81 and onward
autocmd Filetype javascript let &colorcolumn=join(range(81,999),",")
" nnoremap <ALT-Up> ddP<ESC>

" powerline
python from powerline.vim import setup as powerline_setup
python powerline_setup()
python del powerline_setup

set laststatus=2
