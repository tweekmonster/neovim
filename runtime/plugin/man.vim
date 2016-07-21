if exists('g:loaded_man')
  finish
endif
let g:loaded_man = 1

let g:man_find_window =
      \ get( g:, 'man_find_window', 1 )

command! -complete=customlist,man#Complete -nargs=* Man call
      \ man#get_page((tabpagenr()-1).'tabnew', <f-args>)
