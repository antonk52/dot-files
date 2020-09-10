function! antonk52#flow#check() abort
    let exe = 'npx flow --timeout 5 --retry-if-init false --from vim'
    let cmd = exe.' "'.expand('%:p').'" 2> /dev/null'
    let flow_result = system(cmd)

    " Handle the server still initializing
    if v:shell_error == 1
        echohl WarningMsg
        echomsg 'Flow server is still initializing...'
        echohl None
        cclose
        return 0
    endif

    " Handle timeout
    if v:shell_error == 3
        echohl WarningMsg
        echomsg 'Flow timed out, please try again!'
        echohl None
        cclose
        return 0
    endif

    let flow_errorfmt = '%EFile "%f"\, line %l\, characters %c-%.%#,%Z%m,%-G%.%#'
    let old_fmt = &errorformat
    let &errorformat = flow_errorfmt

    cgete flow_result
    " open quickfix window from arg but do not jump to locations
    cwindow
    echo ''

    let &errorformat = old_fmt
endfunction
