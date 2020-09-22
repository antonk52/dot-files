function! antonk52#typescript#check() abort
    let cmd = 'npx tsc --noEmit'
    let tsc_result = system(cmd)

    " Handle the server still initializing
    if v:shell_error == 1
        echohl WarningMsg
        echomsg 'Tsc server is still initializing...'
        echohl None
        cclose
        return 0
    endif

    " Handle timeout
    if v:shell_error == 3
        echohl WarningMsg
        echomsg 'Tsc timed out, please try again!'
        echohl None
        cclose
        return 0
    endif

    let tsc_errorfmt='%+A\ %#%f\ %#(%l\\\,%c):\ %m,%C%m'
    let old_fmt = &errorformat
    let &errorformat = tsc_errorfmt

    cgete tsc_result
    cwindow
    echo ''

    let &errorformat = old_fmt

    if (&syntax != 'qf')
        echo 'No errors!'
    endif
endfunction
