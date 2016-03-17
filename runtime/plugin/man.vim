if exists('g:loaded_man')
  finish
endif
let g:loaded_man = 1

let g:neoman_find_window =
      \ get( g:, 'neoman_find_window', 1 )

command! -bang -complete=customlist,man#Complete -nargs=* Man call
      \ man#get_page(<bang>0, (tabpagenr()-1).'tabnew', <f-args>)
