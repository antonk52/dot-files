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
