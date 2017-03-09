" Vim filetype plugin file
" Language:         Vim help file
" Maintainer:       Nikolai Weibull <now@bitwi.se>
" Latest Revision:  2008-07-09

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

let b:undo_ftplugin = "setl fo< tw< cole< cocu<"

setlocal formatoptions+=tcroql textwidth=78
if has("conceal")
  setlocal cole=2 cocu=nc
endif

function! s:create_toc() abort
  if !exists('b:help_toc')
    let b:help_toc = []
    let lnum = 2
    let last_line = line('$') - 1
    let last_added = 0
    let has_section = 0
    let has_sub_section = 0

    while lnum <= last_line
      let level = 0
      let add_text = ''
      let text = getline(lnum)

      if text =~# '^=\+$' && lnum + 1 < last_line
        " A de-factor section heading.  Other headings are inferred.
        let has_section = 1
        let has_sub_section = 0
        let lnum = nextnonblank(lnum + 1)
        let text = getline(lnum)
        let add_text = text
        while add_text =~# '\*[^*]\+\*\s*$'
          let add_text = matchstr(add_text, '.*\ze\*[^*]\+\*\s*$')
        endwhile
      elseif text =~# '^[A-Z0-9][-A-ZA-Z0-9 .][-A-Z0-9 .():]*\%([ \t]\+\*.\+\*\)\?$'
        " Any line that's yelling is important.
        let has_sub_section = 1
        let level = has_section
        let add_text = matchstr(text, '.\{-}\ze\s*\%([ \t]\+\*.\+\*\)\?$')
      elseif text =~# '\~$'
            \ && matchstr(text, '^\s*\zs.\{-}\ze\s*\~$') !~# '\t\|\s\{2,}'
            \ && getline(lnum - 1) =~# '^\s*<\?$\|^\s*\*.*\*$'
            \ && getline(lnum + 1) =~# '^\s*>\?$\|^\s*\*.*\*$'
        " These lines could be headers or code examples.  We only want the
        " ones that have subsequent lines at the same indent or more.
        let l = nextnonblank(lnum + 1)
        if getline(l) =~# '\*[^*]\+\*$'
          " Ignore tag lines
          let l = nextnonblank(l + 1)
        endif

        if indent(lnum) <= indent(l)
          let level = has_section + has_sub_section
          let add_text = matchstr(text, '\S.*')
        endif
      endif

      let add_text = substitute(add_text, '\s\+$', '', 'g')
      if !empty(add_text) && last_added != lnum
        let last_added = lnum
        call add(b:help_toc, {'bufnr': bufnr('%'), 'lnum': lnum,
              \ 'text': repeat('  ', level) . add_text})
      endif
      let lnum += 1
    endwhile
  endif

  call setloclist(0, b:help_toc, ' ', {'title': 'Help TOC'})
endfunction

autocmd BufWinEnter <buffer> call s:create_toc()

let &cpo = s:cpo_save
unlet s:cpo_save
