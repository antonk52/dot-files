" default
" +--  7 lines: set foldmethod=indent··············
"
" new
" ⏤⏤⏤⏤► [7 lines]: set foldmethod=indent ⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤
"
function! antonk52#fold#it() abort
  let l:start_arrow = '⏤⏤⏤⏤► '
  let l:lines='[' . (v:foldend - v:foldstart + 1) . ' lines]'
  let l:first_line=substitute(getline(v:foldstart), '\v *', '', '')
  return l:start_arrow . l:lines . ': ' . l:first_line . ' '
endfunction
