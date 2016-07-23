if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

if expand('%') !~# '^man:\/\/'
  call man#normalize_page()
  silent execute 'file '.'man://'.tolower(matchstr(getline(1), '^\S\+'))
endif

setlocal buftype=nofile
setlocal noswapfile
setlocal nofoldenable
setlocal bufhidden=hide
setlocal nobuflisted
setlocal nomodified
setlocal readonly
setlocal nomodifiable
setlocal noexpandtab
setlocal tabstop=8
setlocal softtabstop=8
setlocal shiftwidth=8
setlocal nolist
setlocal foldcolumn=0
setlocal colorcolumn=0
setlocal keywordprg=:Man

if !exists('g:no_plugin_maps') && !exists('g:no_man_maps')
  nnoremap <silent> <buffer> <C-]> K
  nnoremap <silent> <buffer> <C-t>    :call man#pop_tag()<CR>
  nnoremap <silent> <nowait><buffer>  <C-W>c
endif

if exists('g:ft_man_folding_enable') && (g:ft_man_folding_enable == 1)
  setlocal foldmethod=indent foldnestmax=1 foldenable
endif

let b:undo_ftplugin = ''
" vim: set sw=2:
