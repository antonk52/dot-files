let s:output = ''

function! s:OnEvent(job_id, data, event) dict
    " collect stdout
    if a:event == 'stdout'
        let s:output = s:output . join(a:data, '\n')
    " report an error
    elseif a:event == 'stderr'
        echohl WarningMsg
        echomsg 'An error occured: ' . join(a:data, '\n')
        echohl None
    " report and clean up
    else
        let tsc_errorfmt='%+A\ %#%f\ %#(%l\\\,%c):\ %m,%C%m'
        let old_fmt = &errorformat
        let &errorformat = tsc_errorfmt

        cgete s:output
        cwindow
        echo ''

        let &errorformat = old_fmt

        if (&syntax != 'qf')
            echo 'No errors!'
        endif

        let s:output = ''
    endif
endfunction

let s:callbacks = {
\ 'on_stdout': function('s:OnEvent'),
\ 'on_stderr': function('s:OnEvent'),
\ 'on_exit': function('s:OnEvent')
\ }

function! antonk52#typescript#check() abort
    let job_id = jobstart(
        \ ['npx', 'tsc', '--noEmit'],
        \ extend({'shell': 'shell MakeTs'}, s:callbacks)
        \ )
endfunction
