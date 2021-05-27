let s:layout_cmd = ''

" restores the split layout
function! antonk52#layout#restore_layout()
    " do nothing if there are no splits
    if 1 == winnr('$')
        return
    endif
    let restore_layout_cmd = winrestcmd()
    if exists('s:layout_cmd')
        exe s:layout_cmd
        unlet s:layout_cmd
    else
        let s:layout_cmd = restore_layout_cmd
    endif
endfunction

function! antonk52#layout#equalify_splits()
    let s:layout_cmd = winrestcmd()
    " only double quotes would work here
    silent execute "normal! \<c-w>\<c-=>"
    echo ''
endfunction

function! antonk52#layout#zoom_split()
    let s:layout_cmd = winrestcmd()
    silent execute "normal! \<c-w>\<c-_>"
    echo ''
endfunction
