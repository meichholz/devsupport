set foldmethod=marker
let maplocalleader=g:My_Leader
let g:L_ProjectDirectory=getcwd()
let g:L_unit_test_dir = "tests/unit"
let g:L_mock_dir = "tests/unit"
let g:L_source_dir = "src"
let g:L_func_test_dir = "tests/functional"

function! s:setupProject() "{{{ initial function to setup variables
	let g:L_project_type="checklib"
	if isdirectory("gtest")
    let g:L_project_type = "gtest"
	endif
	" Guess C extension in this project. CC wins over C.
  let g:L_cext="c"
	if glob("**/*.cc")!=""
		let g:L_cext="cc"
	elseif glob("**/*.cpp")!=""
		let g:L_cext="cpp"
	endif
	let g:L_cdotext=".".g:L_cext
	" echomsg "type/ext:" g:L_project_type "/" g:L_cext
endfunction
"}}}
function! s:moduleName(...) " {{{ strip everything, including extension, from the file name
	let l:name = exists('a:1') ? a:1 : expand('%:t')
  return substitute( substitute(l:name, '^test_', '', 'g'),
				\"\\.[a-z]\\+","","g")
endfunction
"}}}
function! s:moduleType(...) "{{{
	let l:name = exists('a:1') ? a:1 : expand('%:t')
  return substitute(l:name, "^.\\+\\.", "", "g") 
endfunction
"}}}
function! s:echoWarning(...) "{{{
	echohl WarningMsg
	execute "echomsg '".join(a:000,"")."'"
	echohl None
endfunction
"}}}
function! L_CycleRelated() "{{{
	cclose
	" fqname is with short path
	let l:fqname=expand('%')
	let l:ext=expand('%:e')
	let l:dir=expand("%:h")
	let l:basename=s:moduleName()
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
		call s:echoWarning("no relation file for ",l:fqname)
		return
	endif
	if filereadable(l:relatedname)
		echomsg "switching to" l:relatedname
		exe "next ".l:relatedname
	else
		call s:echoWarning("file does not exist: ", l:relatedname)
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
function! s:editJumpToFirstInList(type, searchcore, candidates) "{{{
	if empty(a:candidates)
		call s:echoWarning("no ", a:type, " file for ", a:searchcore)
		return
	endif
	echo a:type.' for <'.a:searchcore.'> finds: '.a:candidates
	let l:filelist = split(a:candidates," ")
	let l:newfile = l:filelist[0]
	exec "next ".l:newfile
endfunction
"}}}
function! L_EditUnittest(...) "{{{
	let l:search_name = exists('a:1') ? a:1 : s:moduleName()
	let l:files = globpath(g:L_unit_test_dir, 'test_'.l:search_name.'*.'.g:L_cext)
	call s:editJumpToFirstInList("unit test",l:search_name,l:files)
endfunction	
"}}}
function! L_EditMock(...) "{{{
	let l:search_name = exists('a:1') ? a:1 : s:moduleName()
	let l:files = globpath(g:L_mock_dir, 'mock_'.l:search_name.'*.'.g:L_cext)
	call s:editJumpToFirstInList("mock module",l:search_name,l:files)
endfunction	
"}}}
function! L_EditFunctionaltest(...) "{{{
	let l:search_name = exists('a:1') ? a:1 : s:moduleName()
	let l:files = globpath(g:L_func_test_dir, l:search_name.'*')
	call s:editJumpToFirstInList("functional test",l:search_name,l:files)
endfunction	
"}}}
function! L_EditCmodule(...) "{{{
	let l:search_name = exists('a:1') ? a:1 : s:moduleName()
	let l:files = globpath(g:L_source_dir, l:search_name.'*.'.g:L_cext)
	call s:editJumpToFirstInList("module",l:search_name,l:files)
endfunction	
"}}}
function! L_EditCheader(...) "{{{
	let l:search_name = exists('a:1') ? a:1 : s:moduleName()
	let l:files = globpath(g:L_source_dir, l:search_name.'*.h')
	call s:editJumpToFirstInList("header",l:search_name,l:files)
endfunction
"}}}
function! L_EditMakefile(...) "{{{
	let l:subdir = expand("%:h")
	let l:variants = [ "Makefile.am", "Makefile.in", "Makefile" ]
	let l:target = ''
	for i in l:variants
		if filereadable(l:subdir."/".i)
			let l:target = l:subdir."/".i
			break
		endif
	endfor
	if empty(l:target)
		call s:editWarning("no suitable Makefile found")
		return
	endif
	execute "next ".l:target
endfunction	
"}}}
function! L_EditCMakeLists(...) "{{{
	let l:subdir = expand("%:h")
	let l:variants = [ "CMakeLists", "CMakeLists.txt", "cmakelists.txt" ]
	let l:target = ''
	for i in l:variants
		if filereadable(l:subdir."/".i)
			let l:target = l:subdir."/".i
			break
		endif
	endfor
	if empty(l:target)
		call s:editWarning("no suitable CMakeLists found")
		return
	endif
	execute "next ".l:target
endfunction	
"}}}

function! L_Test()
	echo s:moduleName()
	echo s:moduleName("test_schnippie.exo")
	echo s:moduleType("test_schnippie.exo")
endfunction

call s:setupProject()

" bindings
command! R call L_CycleRelated()
command! -nargs=0 Emakefile call L_EditMakefile()
command! -nargs=0 Ecmakelists call L_EditCMakeLists()
command! -nargs=? Eunittest call L_EditUnittest(<f-args>)
command! -nargs=? Emock call L_EditMock(<f-args>)
command! -nargs=? Ecode call L_EditCmodule(<f-args>)
command! -nargs=? Eheader call L_EditCheader(<f-args>)
command! -nargs=? Efunctional call L_EditFunctionaltest(<f-args>)

nmap <F7> :R<CR>
imap <F7> <C-C>:R<CR>

" see: http://learnvimscriptthehardway.stevelosh.com/
command! Lcheck call L_Rake('check')
command! Lcleancheck call L_Rake('cleancheck')
nmap <F10> :Lcheck<CR><CR>
nmap <S-F10> :Lcleancheck<CR><CR>
nnoremap <localleader>lrc :Lcheck<CR><CR>
nnoremap <localleader>lrcc :Lcleancheck<CR><CR>
" some debug convenience
nmap <localleader>lt :call L_Test()<CR>
nmap <localleader>lrv :w!<CR>:source local_checklib_project.vim<CR>

" vim: fdm=marker ts=2 sw=2

