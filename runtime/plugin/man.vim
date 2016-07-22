if exists('g:loaded_man')
  finish
endif
let g:loaded_man = 1

let g:man_find_window = get(g:, 'man_find_window', 1 )

command! -count=10 -complete=customlist,man#complete -nargs=* Man call
      \ man#get_page(<count>, (tabpagenr()-1).'tabnew', <f-args>)

nnoremap <silent> <Plug>(Man) :<C-u>call man#get_page(v:count, (tabpagenr()-1).'tabnew', expand('<cWORD>'))<CR>
