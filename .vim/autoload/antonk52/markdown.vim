function! antonk52#markdown#toggle_checkbox()
    " save cursor position
    let cursor_position = getpos('.')
    let content = getline('.')
    let res = match(content, '\[ \]')
    if res == -1
        execute('.s/\[x\]/[ ]')
    else
        execute('.s/\[ \]/[x]')
    endif
    " restore cursor position
    call setpos('.', cursor_position)
endfunction

function! antonk52#markdown#conceal_intensifies()
    syn region markdownLinkText matchgroup=markdownLinkTextDelimiter
        \ start="!\=\[\%(\_[^]]*]\%( \=[[(]\)\)\@=" end="\]\%( \=[[(]\)\@="
        \ keepend nextgroup=markdownLink,markdownId
        \ skipwhite contains=@markdownInline,markdownLineStart concealends
    syn region markdownLink matchgroup=markdownLinkDelimiter start="(" end=")"
        \ contains=markdownUrl keepend contained conceal
    syn region markdownUrl matchgroup=markdownUrlDelimiter start="<" end=">"
        \ contained conceal
    setlocal conceallevel=3
    " hide tilde sign on empty lines
    hi! EndOfBuffer ctermbg=bg ctermfg=bg guibg=bg guifg=bg
endfunction

function! antonk52#markdown#source_rus_keymap() abort
    let filename = "keymap/russian-jcukenmac.vim"
    let rus_keymap = trim(globpath(&rtp, filename))
    if (filereadable(rus_keymap))
        execute("source " . rus_keymap)
        echo 'Russian keymap sourced'
    else
        echom 'Cannot locate Russian keymap file named "' . filename . '"'
    endif
endfunction

function! antonk52#markdown#setup()
    nnoremap <silent> <localleader>t :call antonk52#markdown#toggle_checkbox()<cr>
    nnoremap <buffer> j gj
    nnoremap <buffer> k gk

    " enable spell & turn on autocompletion from the spell file
    autocmd! CursorHold * ++once setlocal spell spelllang=ru_ru,en_us spellsuggest
endfunction
