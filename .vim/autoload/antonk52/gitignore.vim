function! antonk52#gitignore#completion(arg_lead, cmd_line, curstor_pos)
    let langs = ['Haskell', 'Lua', 'Node', 'PureScript', 'Python', 'Rust', 'Swift']
    if a:arg_lead == ''
        return langs
    endif

    let result = []
    for lang in langs
        if stridx(lang, a:arg_lead) == 0
            call add(result, lang)
        endif
    endfor
    return result
endfunction

function! antonk52#gitignore#impl(lang)
    let curl_cmd = '!curl -s https://raw.githubusercontent.com/github/gitignore/master/'.a:lang.'.gitignore'
    let content = execute(curl_cmd)
    let lines_but_cmd = split(content, '\n')[2:]
    call append(line('$'), lines_but_cmd)
endfunction
