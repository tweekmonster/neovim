if exists('g:loaded_man')
  finish
endif
let g:loaded_man = 1

if !exists('g:man_find_window')
  let g:man_find_window = 1
endif

if !exists('g:man_synopsis')
  let g:man_synopsis = '\V\^SYNOPSIS\$'
endif

command! -bang -complete=customlist,man#Complete -nargs=* Man call
      \ man#get_page(<bang>0, (tabpagenr()-1).'tabnew', <f-args>)
