let s:man_cmd = 'man 2>/dev/null'
" regex for valid extensions that manpages can have
let s:man_extensions = '[glx]z\|bz2\|lzma\|Z'
let s:man_tag_stack = []
function! man#get_page(bang, editcmd, ...) abort
  " fpage is a string like 'printf(2)'
  if empty(a:000)
    let fpage = expand('<cWORD>')
    if empty(fpage)
      call s:error("no WORD under cursor")
      return
    endif
  elseif len(a:000) > 2
    call s:error('too many arguments')
    return
  elseif len(a:000) == 1
    let fpage = a:000[0]
  else
    let fpage = a:000[1].'('.a:000[0].')'
  endif

  " if fpage is a path, no need to parse anything
  if fpage =~# '\/'
    let page = fpage
    let sect = ''
  else
    let [page, sect] = s:parse_page_and_section(fpage)
    if empty(page)
      call s:error('invalid manpage name '.fpage)
      return
    endif
    let path = s:find_page(sect, page)
    if empty(path)
      call s:error("no manual entry for ".fpage)
      return
    elseif empty(sect)
      let sect = s:parse_sect(path[0])
    endif
  endif

  call s:push_tag_stack()

  if g:find_man_window != a:bang && &filetype !=# 'man'
    let cmd = s:find_man(a:editcmd)
  else
    let cmd = a:editcmd
  endif

  call s:read_page(sect, page, cmd)
endfunction

" move to previous position in the stack
function! man#pop_tag_stack() abort
  if !empty(s:man_tag_stack)
    execute s:man_tag_stack[-1]['buf'].'b'
    execute s:man_tag_stack[-1]['lin']
    execute 'normal! '.s:man_tag_stack[-1]['col'].'|'
    call remove(s:man_tag_stack, -1)
  endif
endfunction

" save current position
function! s:push_tag_stack() abort
  let s:man_tag_stack = add(s:man_tag_stack, {
        \ 'buf': bufnr('%'),
        \ 'lin': line('.'),
        \ 'col': col('.')
        \ })
endfunction

" find the closest man window above/left
function! s:find_man(cmd) abort
  if winnr('$') > 1
    let thiswin = winnr()
    while 1
      if &filetype ==# 'man'
        return 'edit'
      endif
      wincmd w
      if thiswin == winnr() | break | endif
    endwhile
  endif
  return a:cmd
endfunction

" parses the sect/page out of 'page(sect)'
function! s:parse_page_and_section(fpage) abort
  let ret = split(a:fpage, '(')
  if len(ret) == 2 && ret[1] =~# '^\f\+)\f*$'
    let iret = split(ret[1], ')')
    return [ret[0], iret[0]]
  elseif len(ret) == 1
    return [ret[0], '']
  else
    return ['', '']
  endif
endfunction

" returns the path of a manpage
function! s:find_page(sect, page) abort
  return split(system(s:man_cmd.' -w '.a:sect.' '.a:page), '\n')
endfunction

" parses the section out of the path to a manpage
function! s:parse_sect(path) abort
  let tail = fnamemodify(a:path, ':t')
  if fnamemodify(tail, ":e") =~# '\%('.s:man_extensions.'\)\n'
    let tail = fnamemodify(tail, ':r')
  endif
  return substitute(tail, '\f\+\.\([^.]\+\)', '\1', '')
endfunction

function! s:read_page(sect, page, cmd)
  silent execute a:cmd 'man://'.a:page.(empty(a:sect)?'':'('.a:sect.')')
  setlocal modifiable
  " remove all the text, incase we already loaded the manpage before
  silent keepjumps normal! gg"_dG
  let $MANWIDTH = winwidth(0)-1
  " read manpage into buffer
  silent execute 'r!'.s:man_cmd.' '.a:sect.' '.a:page
  " remove all those backspaces
  silent! keepjumps %substitute,.,,g
  " remove blank lines from top and bottom.
  while getline(1) =~# '^\s*$'
    silent keepjumps 1delete _
  endwhile
  while getline('$') =~# '^\s*$'
    silent keepjumps $delete _
  endwhile
  keepjumps normal! gg
  setlocal filetype=man
endfunction

function! s:error(msg) abort
  redraws!
  echon "man: "
  echohl ErrorMsg
  echon a:msg
  echohl None
endfunction

function! man#Complete(ArgLead, CmdLine, CursorPos) abort
  let args = split(a:CmdLine)
  let l = len(args)
  " if the cursor (|) is at ':Man printf(|' then
  " make sure to display the section. See s:get_candidates
  let fpage = 0
  " if already completed a manpage, we return
  if (l > 1 && args[1] =~# ')\f*$') || l > 3 || a:ArgLead =~# ')$'
    return
  elseif l == 3
    " cursor (|) is at ':Man 3 printf |'
    if empty(a:ArgLead)
      return
    endif
    let sect = args[1]
    let page = args[2]
  elseif l == 2
    " cursor (|) is at ':Man 3 |'
    if empty(a:ArgLead)
      let page = ""
      let sect = args[1]
    elseif a:ArgLead =~# '^\f\+(\f*$'
      " cursor (|) is at ':Man printf(|'
      let tmp = split(a:ArgLead, '(')
      let page = tmp[0]
      let sect = substitute(get(tmp, 1, '*'), ')$', '', '').'*'
      let fpage = 1
    else
      " cursor (|) is at ':Man printf
      let page = args[1]
      let sect = '*'
    endif
  else
    let page = ''
    let sect = '*'
  endif
  return s:get_candidates(page, sect, fpage)
endfunction

function! s:get_candidates(page, sect, fpage) abort
  let mandirs = s:MANDIRS()
  let candidates = globpath(mandirs, "*/" . a:page . "*." . a:sect, 0, 1)
  let find = '\(.\+\)\.\%('.s:man_extensions.'\)\@!\'
  " if the page is a path, complete files
  if a:sect ==# '*' && a:page =~# '\/'
    "TODO why does this complete the last one automatically
    let candidates = glob(a:page.'*', 0, 1)
  else
    " if the section is not empty and the cursor (|) is not at
    " ':Man printf(|' then do not show sections.
    if a:sect != '*' && !a:fpage
      let find .= '%([^.]\+\).*'
      let repl = '\1'
    else
      let find .= '([^.]\+\).*'
      let repl = '\1(\2)'
    endif
    for i in range(len(candidates))
      let candidates[i] = substitute((fnamemodify(candidates[i], ":t")), find, repl, "")
    endfor
  endif
  return candidates
endfunction

function! s:MANDIRS() abort
  " gets list of MANDIRS
  let mandirs_list = split(system(s:man_cmd.' -w'), ':\|\n')
  " removes duplicates and then joins by comma
  return join(filter(mandirs_list, 'index(mandirs_list, v:val, v:key+1)==-1'), ',')
endfunction
