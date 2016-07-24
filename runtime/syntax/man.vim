" TODO(nhooyr) use backspaced text for better syntax highlighting.
" see https://github.com/neovim/neovim/pull/4449#issuecomment-234696194

if exists('b:current_syntax')
  finish
endif

syntax case  ignore
syntax match manReference       '\f\+(\%([0-8][a-z]\=\|n\))'
syntax match manTitle           '^\%1l\S\+\%((\%([0-8][a-z]\=\|n\))\)\=.*$'
syntax match manSubHeading      '^\s\{3\}\%(\S.*\)\=\S$'
syntax match manOptionDesc      '^\s\+[+-]\S\+'
syntax match manLongOptionDesc  '^\s\+--\S\+'
syntax match manBold            '\%o225\%(\%o225\@!.\)\{-}\%o225' containedin=TOP contains=manBoldDelim
syntax match manUnderline       '\%o246\%(\%o246\@!.\)\{-}\%o246' containedin=TOP contains=manUnderlineDelim
syntax match manBoldDelim       '\%o225' contained conceal
syntax match manUnderlineDelim  '\%o246' contained conceal

" prevent manSectionHeading from matching last line
execute 'syntax match manSectionHeading  "^\%(\%>1l\%<'.line('$').'l\)\%(\S.*\)\=\S$" contains=manBoldDelim'

highlight default link manTitle          Title
highlight default link manSectionHeading Statement
highlight default link manOptionDesc     Constant
highlight default link manLongOptionDesc Constant
highlight default link manReference      PreProc
highlight default link manSubHeading     Function
highlight default link manBold           Keyword
highlight default manBold cterm=bold gui=bold
highlight default manUnderline cterm=underline gui=underline

if getline(1) =~# '^\f\+([23][a-zA-Z]\=)'
  syntax include @cCode $VIMRUNTIME/syntax/c.vim
  syntax match manCFuncDefinition display '\<\h\w*\>\s*('me=e-1 contained
  syntax region manSynopsis start='\V\^\%(
        \SYNOPSIS\|
        \SYNTAX\|
        \SINTASSI\|
        \SKŁADNIA\|
        \СИНТАКСИС\|
        \書式\)\$'hs=s+8 end='^\%(\S.*\)\=\S$'me=e-12 keepend contains=manSectionHeading,@cCode,manCFuncDefinition
  highlight default link manCFuncDefinition Function
endif

let b:current_syntax = 'man'
