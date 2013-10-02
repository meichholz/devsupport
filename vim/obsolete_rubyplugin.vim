let maplocalleader = g:My_Leader 

function! s:ObsoletedStuff() "{{{
	" see http://po-ru.com/diary/running-ruby-tests-from-vim/ for a better solution
	" and httpg://github.com/SoftwareWithFriends/vi-settings/blob/master/bin/ruby-run-focused-unit-test
	" and finally httpg://github.com/threedaymonk/config
	" IDEA: Put such stuff into a project local(!) vim module
	nmap <localleader>rft :w!<CR>V:<C-U>!$HOME/.vim/bin/ruby-run-focused-unit-test % <C-R>=line("'<")<CR>p <CR>

	" idiom: insert ERB value
	nmap <localleader>iv <ESC>i<%=   %><ESC>3<LEFT>i
endfunction "}}}
" generic make support variables for ruby {{{
let s:rubyArgs    = ""
let s:makeArgs    = "test"
let s:bufferArgs  = ""
let s:rakeCommand = "rake"
" }}}
function! s:SetRake()"{{{
  compiler ruby
	exe "set makeprg=".s:rakeCommand
endfunction
"}}}
function! s:Input ( promp, text, ... )"{{{
  echohl Search                                         " highlight prompt
  call inputsave()                                      " preserve typeahead
  if a:0 == 0 || empty(a:1)
    let retval  =input( a:promp, a:text )
  else
    let retval  =input( a:promp, a:text, a:1 )
  endif
  call inputrestore()                                   " restore typeahead
  echohl None                                           " reset highlightin     g
  let retval  = substitute( retval, '^\s\+', "", "" )   " remove leading wh     itespaces
  let retval  = substitute( retval, '\s\+$', "", "" )   " remove trailing w     hitespaces
  return retval
endfunction
"}}}

  function! R_GetMakeArguments()" {{{
          let s:makeArgs=R_Input( 'rake/make targets or argumentg: ', s:makeArgs, 'file' )
  endfunction
  "}}}
  function! R_GetBufferArguments()"{{{
          let s:bufferArgs=R_Input( 'buffer program argumentg: ', s:bufferArgs, 'file' )
  endfunction
  "}}}
  function! R_GetRubyArguments()"{{{
          let s:rubyArgs=R_Input( 'ruby interpreter argumentg: ', s:rubyArgs, 'file' )
  endfunction
  "}}}
  function! R_GetMakeCommand()"{{{
          let s:rakeCommand=R_Input( 'make/rake program with general optiong: ', s:rakeCommand, 'file' )
  endfunction
  " }}}
  function! R_CallRakeTest()"{{{
          exe     ":cclose"
          exe     ":update"
          call	s:SetRake()
          exe     ":make -t test"
          exe     ":botright cwindow"
  endfunction
  "}}}
  function! R_CallRake()"{{{
          call	s:SetRake()
          exe     ":cclose"
          exe     ":update"
          exe     ":make ".s:makeArgs
          exe     ":botright cwindow"
  endfunction
  "}}}
  function! R_RunBuffer()"{{{
          set	makeprg=ruby
          exe     ":cclose"
          exe     ":update"
          exe     ":make ".s:rubyArgs." %".s:bufferArgs
          exe     ":botright cwindow"
  endfunction
  "}}}

call s:SetRake()

nnoremap <localleader>rma :call R_GetMakeArguments()<CR>
nnoremap <localleader>rmcc :call R_GetMakeCommand()<CR>
nnoremap <localleader>rba :call R_GetBufferArguments()<CR>
nnoremap <localleader>rra :call R_GetRubyArguments()<CR>
nnoremap <localleader>rmcc :call R_GetMakeCommand()<CR>
nnoremap <localleader>rmt :call R_CallRakeTest()<CR>
nnoremap <localleader>rm :call R_CallRake()<CR>
nnoremap <localleader>rr :call R_RunBuffer()<CR>

" vim: set fdm=marker ts=22 :
