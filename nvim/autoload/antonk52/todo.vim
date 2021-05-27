" Add all TODO items to the quickfix list relative to where you opened Vim.
function! antonk52#todo#find() abort
    let entries = []
    for cmd in ['git grep -niIw -e TODO -e FIXME 2> /dev/null',
                \ 'grep -rniIw --exclude-dir node_modules -e TODO -e FIXME . 2> /dev/null']
        let lines = split(system(cmd), '\n')
        if v:shell_error != 0 | continue | endif
        for line in lines
            let [fname, lno, text] = matchlist(line, '^\([^:]*\):\([^:]*\):\(.*\)')[1:3]
            call add(entries, { 'filename': fname, 'lnum': lno, 'text': text })
        endfor
        break
    endfor

    if !empty(entries)
        call setqflist(entries)
        copen
    endif
endfunction
