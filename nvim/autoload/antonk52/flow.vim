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
        let flow_errorfmt = '%EFile "%f"\, line %l\, characters %c-%.%#,%Z%m,%-G%.%#'
        let old_fmt = &errorformat
        let &errorformat = flow_errorfmt

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

function! antonk52#flow#check() abort
    let job_id = jobstart(
        \ ['npx', 'flow', '--timeout', '5', '--retry-if-init', 'false', '--from', 'vim'],
        \ extend({'shell': 'shell MakeFlow'}, s:callbacks)
        \ )
endfunction
