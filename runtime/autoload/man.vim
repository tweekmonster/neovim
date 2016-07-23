" Ensure Vim is not recursively invoked (man-db does this)
" by removing MANPAGER from the environment
" More info here http://comments.gmane.org/gmane.editors.vim.devel/29085
if &shell =~# 'fish$'
  let s:man_cmd = 'man -P cat ^/dev/null '
else
  let s:man_cmd = 'man -P cat 2>/dev/null '
endif

" regex for valid extensions that manpages can have
let s:man_extensions = '[glx]z\|bz2\|lzma\|Z'
let s:man_sect_arg = ''
let s:man_find_arg = '-w'
let s:tag_stack = []

try
  if !has('win32') && $OSTYPE !~? 'cygwin\|linux' && system('uname -s') =~? 'SunOS' && system('uname -r') =~? '^5'
    let s:man_sect_arg = '-s'
    let s:man_find_arg = '-l'
  endif
catch /E145:/
  " Ignore the error in restricted mode
endtry

function! man#get_page(count, editcmd, ...) abort
  if a:0 > 2
    call s:error('too many arguments')
    return
  elseif a:0 == 0
    call s:error('what manual page do you want?')
    return
  elseif a:0 == 1
    let [page, sect] = s:parse_page_and_sect_fpage(a:000[0])
    if empty(sect) && a:count != 10
      let sect = a:count
    endif
  else
    let sect = tolower(a:000[0])
    let page = a:000[1]
  endif

  let out = systemlist(s:man_cmd.s:man_find_arg.' '.s:man_args(sect, page))
  if empty(out) || out[0] == ''
    call s:error('no manual entry for '.page.(empty(sect)?'':'('.sect.')'))
    return
  elseif page !~# '\/' " if page is not a path, parse the page and section from the path
    " use the last line because if we had something like printf(man) then man
    " would be read as the manpage because man's path is at out[0]
    let [page, sect] = s:parse_page_and_sect_path(out[len(out)-1])
  endif

  call s:push_tag()

  call s:read_page(sect, page, a:editcmd)
endfunction

" move to previous position in the stack
function! man#pop_tag() abort
  if !empty(s:tag_stack)
    let tag = remove(s:tag_stack, -1)
    execute tag['buf'].'b'
    call cursor(tag['lnum'], tag['col'])
  endif
endfunction

" save current position in the stack
function! s:push_tag() abort
  let s:tag_stack += [{
        \ 'buf':  bufnr('%'),
        \ 'lnum': line('.'),
        \ 'col':  col('.'),
        \ }]
endfunction

" find the closest man window above/left
function! s:find_man(cmd) abort
  if g:man_find_window != 1 || &filetype ==# 'man'
    return a:cmd
  endif
  if winnr('$') > 1
    let thiswin = winnr()
    while 1
      if &filetype ==# 'man'
        return 'edit'
      endif
      wincmd w
      if thiswin == winnr()
        return a:cmd
      endif
    endwhile
  endif
  return a:cmd
endfunction

" parses the page and sect out of 'page(sect)'
function! s:parse_page_and_sect_fpage(fpage) abort
  let ret = split(a:fpage, '(')
  if len(ret) > 1
    let iret = split(ret[1], ')')
    return [ret[0], tolower(iret[0])]
  else
    return [ret[0], '']
  endif
endfunction

" parses the page and sect out of 'path/page.sect'
function! s:parse_page_and_sect_path(path) abort
  let tail = fnamemodify(a:path, ':t')
  if fnamemodify(tail, ':e') =~# s:man_extensions
    let tail = fnamemodify(tail, ':r')
  endif
  let page = matchstr(tail, '^\f\+\ze\.')
  let sect = matchstr(tail, '\.\zs.\+$')
  return [page, sect]
endfunction

function! s:read_page(sect, page, cmd)
  silent execute s:find_man(a:cmd) 'man://'.a:page.(empty(a:sect)?'':'('.a:sect.')')
  setlocal modifiable
  " remove all the text, incase we already loaded the manpage before
  silent keepjumps %delete _
  let $MANWIDTH = winwidth(0)-1
  " read manpage into buffer
  silent execute 'r!'.s:man_cmd.s:man_args(a:sect, a:page)
  call man#normalize_page()
  setlocal filetype=man
endfunction

function! man#normalize_page()
  " remove all those backspaces
  execute "silent keepjumps %substitute,.\b,,ge"
  " remove blank lines from top and bottom.
  while getline(1) =~# '^\s*$'
    silent keepjumps 1delete _
  endwhile
  " TODO(nhooyr) is deleting the bottom lines necessary?
  " I think only deleting the first line is necessary when using r! to
  " read manpage in.
  while getline('$') =~# '^\s*$'
    silent keepjumps $delete _
  endwhile
  keepjumps 1
endfunction

function! s:man_args(sect, page) abort
  if !empty(a:sect)
    return s:man_sect_arg.' '.shellescape(a:sect).' '.shellescape(a:page)
  endif
  return shellescape(a:page)
endfunction

function! s:error(msg) abort
  redrawstatus!
  echon 'man.vim: '
  echohl ErrorMsg
  echon a:msg
  echohl None
endfunction

function! man#complete(ArgLead, CmdLine, CursorPos) abort
  let args = split(a:CmdLine)
  let l = len(args)
  " if the cursor (|) is at ':Man printf(|' then
  " make sure to display the section. See s:get_candidates
  let fpage = 0
  " if already completed a manpage, we return
  if (l > 1 && args[1] =~# ')\f*$') || l > 3
    return
  elseif l == 3
    " cursor (|) is at ':Man 3 printf |'
    if empty(a:ArgLead)
      return
    endif
    let sect = tolower(args[1])
    let page = a:ArgLead
  elseif l == 2
    " cursor (|) is at ':Man 3 |'
    if empty(a:ArgLead)
      let page = ''
      let sect = tolower(args[1])
    elseif a:ArgLead =~# '^\f\+(\f*$'
      " cursor (|) is at ':Man printf(|'
      let tmp = split(a:ArgLead, '(')
      let page = tmp[0]
      let sect = tolower(get(tmp, 1, ''))
      let fpage = 1
    else
      " cursor (|) is at ':Man printf|'
      let page = a:ArgLead
      let sect = ''
    endif
  else
    let page = ''
    let sect = ''
  endif
  return s:get_candidates(page, sect, fpage)
endfunction

function! s:init_mandirs() abort
  " gets list of MANDIRS
  let mandirs_list = split(system(s:man_cmd.s:man_find_arg), ':\|\n')
  " removes duplicates and then join by comma
  let s:mandirs = join(filter(mandirs_list, 'index(mandirs_list, v:val, v:key+1)==-1'), ',')
endfunction
call s:init_mandirs()

function! s:get_candidates(page, sect, fpage) abort
  let candidates = globpath(s:mandirs,'*/'.a:page.'*.'.a:sect.'*', 0, 1)
  " The extension of each candidate must either (have a:sect as a prefix and cannot be part of
  " s:man_extensions) or (it must be part of s:man_extensions and the root of the file name's
  " extension must have a:sect as a prefix).
  call filter(candidates, "(v:val =~# a:sect.'[^.]*$' && v:val !~# s:man_extensions.'$' ) || (v:val =~# s:man_extensions.'$' && fnamemodify(v:val, ':r') =~# a:sect.'[^.]*$')")
  " if the page is a path, complete files
  if empty(a:sect) && a:page =~# '\/'
    "TODO(nhooyr) why does this complete the last one automatically
    let candidates = glob(a:page.'*', 0, 1)
  else
    let find = '\(.\+\)\.\%('.s:man_extensions.'\)\@!\'
    " if the section is not empty and the cursor (|) is not at
    " ':Man printf(|' then do not show sections.
    if !empty(a:sect) && !a:fpage
      let find .= '%([^.]\+\).*'
      let repl = '\1'
    else
      let find .= '([^.]\+\).*'
      let repl = '\1(\2)'
    endif
    call map(candidates, 'substitute((fnamemodify(v:val, ":t")), find, repl, "")')
  endif
  return candidates
endfunction
