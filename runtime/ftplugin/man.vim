if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

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

if !exists('g:no_plugin_maps') && !exists('g:no_man_maps')
  nnoremap <silent> <buffer> <C-]>    :call man#get_page(g:man_find_window, 'edit')<CR>
  nmap     <silent> <buffer> <K>      <C-]>
  nnoremap <silent> <buffer> <C-t>    :call man#pop_tag()<CR>
  nnoremap <silent> <nowait><buffer>  q <C-W>c
endif

if exists('g:ft_man_folding_enable') && (g:ft_man_folding_enable == 1)
  setlocal foldmethod=indent foldnestmax=1 foldenable
endif

" vim: set sw=2:
