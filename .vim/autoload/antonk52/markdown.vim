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
endfunction
