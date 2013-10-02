" local edit pacakage for gem project
" customizes: https://github.com/vim-ruby/vim-ruby/wiki/VimRubySupport
" History:
" 1.0.1.1 : Marian Eichholz

set foldmethod=marker
let maplocalleader = g:My_Leader
let g:L_ProjectDirectory = getcwd()
let g:L_unit_test_dir = "spec"
let g:L_feature_dir = "features/**"
let g:L_stepdef_dir = "features/step_definitions/**"
let g:L_source_dir = "lib/**"
let g:RakeCheckTask = "test"
" fix search path to generic GEM project structure, LIB precedes BIN.
let g:ruby_path = getcwd()."/lib/*/**,".getcwd()."/**"

function! s:setupProjectType() "{{{ initial function to setup variables
	let g:L_project_type="gem"
  let g:L_rbext="rb"
	let g:L_rbdotext=".".g:L_rbext
	" echomsg "type/ext:" g:L_project_type "/" g:L_rbext
endfunction
"}}}
function! s:ModuleName(...) " {{{ strip everything, including extension, from the file name
	let l:name = exists('a:1') ? a:1 : expand('%:t')
  return substitute( substitute(l:name, '_spec', '', 'g'),
				\"\\.[a-z]\\+","","g")
endfunction
"}}}
function! s:ModuleType(...) "{{{
	let l:name = exists('a:1') ? a:1 : expand('%:t')
  return substitute(l:name, "^.\\+\\.", "", "g") 
endfunction
"}}}
function! s:EchoWarning(...) "{{{
	echohl WarningMsg
	execute "echomsg '".join(a:000,"")."'"
	echohl None
endfunction
"}}}
function! s:editFirstInList(type, searchcore, candidates) "{{{
	if empty(a:candidates)
		call s:EchoWarning("no ", a:type, " file for ", a:searchcore)
		return
	endif
	" echo a:type.' for <'.a:searchcore.'> finds: '.a:candidates
	let l:filelist = split(a:candidates,"\n")
	let l:newfile = l:filelist[0]
	exec "next ".l:newfile
endfunction
"}}}
function! L_CycleRelated() "{{{
	cclose
	call s:EchoWarning("not implemented, bailing out")
	return ""
	" fqname is with short path
	let l:fqname=expand('%')
	let l:ext=expand('%:e')
	let l:dir=expand("%:h")
	let l:basename=s:ModuleName()
	" mocks to cmock.h to Makefile.am to llcheck.h
	if l:ext == g:L_cext && l:fqname=~"/mock*"
    let l:relatedname = l:dir."/cmock.h"
	elseif expand('%:t')=='cmock.h'
		let l:relatedname = l:dir.'/Makefile.am'
	elseif l:basename=="Makefile" && l:dir==g:L_unit_test_dir 
		let l:relatedname = g:L_unit_test_dir."/llcheck.h"
	" FIXME: cycle through file list (mock_*, llcheck_*)
	" from header to code (generic)
	elseif l:ext=="h"
		let l:relatedname=substitute(l:fqname,"\\.h$",g:L_cdotext,"g")
	" from code to test 
	elseif l:ext==g:L_cext && l:dir==g:L_source_dir
		let l:relatedname = g:L_unit_test_dir."/test_".l:basename.g:L_cdotext
	" from test to code
	elseif l:ext==g:L_cext
    let l:relatedname = g:L_source_dir."/".l:basename.g:L_cdotext
	else
		call s:EchoWarning("no relation file for ",l:fqname)
		return
	endif
	if filereadable(l:relatedname)
		echomsg "switching to" l:relatedname
		exe "next ".l:relatedname
	else
		call s:EchoWarning("file does not exist: ", l:relatedname)
	endif
endfunction
" }}}
function! L_Rake(mode) "{{{
  wall
	set makeprg=rake
	execute "make! ".a:mode
	copen
endfunction
" }}}
function! L_EditUnittest(...) "{{{
	let l:search_name = exists('a:1') ? a:1 : s:ModuleName()
	let l:files = globpath(g:L_unit_test_dir, l:search_name.'*_spec.'.g:L_rbext)
	call s:editFirstInList("unit test",l:search_name,l:files)
endfunction	
"}}}
function! L_EditCode(...) "{{{
	let l:search_name = exists('a:1') ? a:1 : s:ModuleName()
	let l:files = globpath(g:L_source_dir, l:search_name.'*.'.g:L_rbext)
	call s:editFirstInList("source code",l:search_name,l:files)
endfunction	
"}}}
function! L_EditFeature(...) "{{{
	let l:search_name = exists('a:1') ? a:1 : s:ModuleName()
	let l:files = globpath(g:L_feature_dir, l:search_name.'*.feature')
	call s:editFirstInList("feature",l:search_name,l:files)
endfunction	
"}}}
function! L_EditStepdefinition(...) "{{{
	let l:search_name = exists('a:1') ? a:1 : s:ModuleName()
	let l:files = globpath(g:L_stepdef_dir, l:search_name.'*.rb')
	call s:editFirstInList("step definition",l:search_name,l:files)
endfunction	
"}}}

function! L_Test()
	echo s:ModuleName("schnippie.exo")
	echo s:ModuleName("schnippie_spec.exo")
	echo s:ModuleType("schnippie.exo")
endfunction

call s:setupProjectType()

" bindings
command! R call L_CycleRelated()
command! -nargs=? Ecode call L_EditCode(<f-args>)
command! -nargs=? Eunittest call L_EditUnittest(<f-args>)
command! -nargs=? Efeature call L_EditFeature(<f-args>)
command! -nargs=? Estep call L_EditStepdefinition(<f-args>)

nmap <F7> :R<CR>
imap <F7> <C-C>:R<CR>

" see: http://learnvimscriptthehardway.stevelosh.com/
command! Lcheck :call L_Rake(g:RakeCheckTask)
command! Lcleancheck :call L_Rake('clobber')<CR>:call L_Rake(g:RakeCheckTask)
nmap <F10> :Lcheck<CR><CR>
nmap <S-F10> :Lcleancheck<CR><CR>
nnoremap <localleader>lrc :Lcheck<CR><CR>
nnoremap <localleader>lrcc :Lcleancheck<CR><CR>
" some debug convenience
nmap <localleader>lt :call L_Test()<CR>


" vim: fdm=marker ts=2 sw=2

