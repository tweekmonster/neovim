if exists('g:loaded_man')
  finish
endif
let g:loaded_man = 1

if !exists("g:find_man_window")
  let g:find_man_window = 1
endif

if !exists('g:man_synopsis')
  let g:man_synopsis = 'SYNOPSIS'
endif

command! -bang -complete=customlist,man#Complete -nargs=* Man call
      \ man#get_page(<bang>0, 'edit', <f-args>)
command! -bang -complete=customlist,man#Complete -nargs=* Sman call
      \ man#get_page(<bang>0, 'split', <f-args>)
command! -bang -complete=customlist,man#Complete -nargs=* Vman call
      \ man#get_page(<bang>0, 'vsplit', <f-args>)
command! -bang -complete=customlist,man#Complete -nargs=* Tman call
      \ man#get_page(<bang>0, 'tabe', <f-args>)
