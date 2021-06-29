function! antonk52#notes#source_rus_keymap() abort
    let filename = "keymap/russian-jcukenmac.vim"
    let rus_keymap = trim(globpath(&rtp, filename))
    if (filereadable(rus_keymap))
        execute("source " . rus_keymap)
        echo 'Russian keymap sourced'
    else
        echom 'Cannot locate Russian keymap file named "' . filename . '"'
    endif
endfunction

function! antonk52#notes#setup() abort
    call antonk52#notes#source_rus_keymap()

    nnoremap <expr> <localleader>s ':Rg tags.*'.expand('<cword>').'<cr>'
endfunction
