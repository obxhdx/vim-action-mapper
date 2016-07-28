" Adapted from http://vim.wikia.com/wiki/Act_on_text_objects_with_custom_functions

function! s:DoAction(algorithm, type)
  " backup settings that we will change
  let sel_save = &selection
  let cb_save = &clipboard

  " make selection and clipboard work the way we need
  set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus

  " backup the unnamed register, which we will be yanking into
  let reg_save = @@

  " yank the relevant text, and also set the visual selection (which will be reused if the text
  " needs to be replaced)
  if a:type =~ '^\d\+$'
    " if type is a number, then select that many lines
    silent exe 'normal! V'.a:type.'$y'
  elseif a:type =~ '^.$'
    " if type is 'v', 'V', or '<C-V>' (i.e. 0x16) then reselect the visual region
    silent exe "normal! `<" . a:type . "`>y"
  elseif a:type == 'line'
    " line-based text motion
    silent exe "normal! '[V']y"
  elseif a:type == 'block'
    " block-based text motion
    silent exe "normal! `[\<C-V>`]y"
  else
    " char-based text motion
    silent exe "normal! `[v`]y"
  endif

  if exists('*'.a:algorithm)
    " call the mapped function, passing it the contents of the unnamed register
    let repl = {a:algorithm}(@@)
  elseif exists(':'.a:algorithm) == 2
    " call the mapped command
    let repl = execute(a:algorithm, 'silent')
  endif

  " if the function returned a value, then replace the text
  if type(repl) == 1 && strlen(repl) > 0
    " put the replacement text into the unnamed register, and also set it to be a
    " characterwise, linewise, or blockwise selection, based upon the selection type of the
    " yank we did above
    call setreg('@', repl, getregtype('@'))
    " relect the visual region and paste
    normal! gvp
  endif

  " restore saved settings and register value
  let @@ = reg_save
  let &selection = sel_save
  let &clipboard = cb_save
endfunction

function! s:ActionOpfunc(type)
  return s:DoAction(s:encode_algorithm, a:type)
endfunction

function! s:ActionSetup(algorithm)
  let s:encode_algorithm = a:algorithm
  let &opfunc = matchstr(expand('<sfile>'), '<SNR>\d\+_') . 'ActionOpfunc'
endfunction

function! MapAction(algorithm, key)
  execute 'nnoremap <silent> <Plug>actions'    .a:algorithm.' :<C-U>call <SID>ActionSetup("'.a:algorithm.'")<CR>g@'
  execute 'xnoremap <silent> <Plug>actions'    .a:algorithm.' :<C-U>call <SID>DoAction("'.a:algorithm.'",visualmode())<CR>'
  execute 'nnoremap <silent> <Plug>actionsLine'.a:algorithm.' :<C-U>call <SID>DoAction("'.a:algorithm.'",v:count1)<CR>'
  execute 'nmap '.a:key.' <Plug>actions'.a:algorithm
  execute 'xmap '.a:key.' <Plug>actions'.a:algorithm
  execute 'nmap '.a:key.a:key[strlen(a:key)-1].' <Plug>actionsLine'.a:algorithm
endfunction

autocmd VimEnter * :doautocmd User MapActions
