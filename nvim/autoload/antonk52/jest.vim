function! antonk52#jest#detect() abort
    let ft = &filetype

    let file = expand('<afile>')
    let test_file = match(file, '\v(_spec|spec|Spec|-test|\.test)\.(js|jsx|ts|tsx)$') != -1
    let indirect_test_file = match(file, '\v/__tests__|tests?/.+\.(js|jsx|ts|tsx)$') != -1

    if test_file || indirect_test_file
        " instead of setting compound file type manually extends current
        " file type snippets to include jest snippets
        execute('UltiSnipsAddFiletypes '.ft.'.jest')
    endif
endfunction
