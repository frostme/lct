set termguicolors
set viminfo^=h
set hls
syntax enable
set guifont=inconsolata:h18
set background=dark
filetype on
filetype plugin on
filetype indent on
set tabstop=2
set shiftwidth=2
set expandtab
colorscheme night-owl
set lines=999
set columns=9999
set noswapfile
set number
set autoread

let g:lightline = {
      \ 'colorscheme': 'night-owl',
      \ }
set laststatus=2
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:vimspector_enable_mappings = 'HUMAN'

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_javascript_checkers = ['eslint']
let vim_markdown_preview_github=1

autocmd vimenter * NERDTree

autocmd FileType typescript setlocal completeopt+=menu,preview
let g:tsuquyomi_disable_quickfix = 0
let g:syntastic_typescript_checkers = ['tsuquyomi'] " You shouldn't use 'tsc' checker.
let g:tsuquyomi_shortest_import_path = 1

let g:prettier#autoformat = 1
let g:prettier#autoformat_require_pragma = 0
let g:prettier#autoformat_config_present = 1
let g:prettier#autoformat_config_files = ['./.prettierrc.toml']
let g:repl_program = {
      \  'typescript': 'ts-node',
      \  'default': 'bash'
      \  }

let g:repl_predefine_bash = {
      \ 'source': '~/.bash_profile'
      \ }

" The Silver Searcher
if executable('ag')
  " Use ag over grep
  set grepprg=ag\ --nogroup\ --nocolor

  " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'

  " ag is fast enough that CtrlP doesn't need to cache
  let g:ctrlp_use_caching = 0
endif

nnoremap <leader>p :Prettier<CR> 

" bind K to grep word under cursor
nnoremap K :grep! "\b<C-R><C-W>\b"<CR>:cw<CR>
command -nargs=+ -complete=file -bar Ag silent! grep! <args>|cwindow|redraw!
nnoremap \ :Ag<SPACE>


nnoremap <leader><Right> gt<CR>
nnoremap <leader><Left> gT<CR>
nnoremap <leader><Up> :tabfirst<CR>
nnoremap <leader><Down> :tablast<CR>
nnoremap <leader><leader><Right> <C-W>l
nnoremap <leader><leader><Left> <C-W>h
nnoremap <leader><leader><Up> <C-W>k
nnoremap <leader><leader><Down> <C-W>j
nnoremap <leader>r :REPLToggle<CR>
nnoremap <leader>h :REPLHide<CR>
nnoremap confr :so $MYVIMRC<CR>
nnoremap <leader>n :cn<CR>
nnoremap <leader>t :tabedit 
nnoremap <leader>s :split<CR> 
nnoremap <leader>vs :vsplit<CR> 
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>tu :tabedit ~/projects/upside/
nnoremap <leader><leader>uu :r!uuid<CR>

nnoremap <Leader>dd :call vimspector#Launch()<CR>
nnoremap <Leader>de :call vimspector#Reset()<CR>
nnoremap <Leader>dc :call vimspector#Continue()<CR>

nnoremap <Leader>dt :call vimspector#ToggleBreakpoint()<CR>
nnoremap <Leader>dT :call vimspector#ClearBreakpoints()<CR>

nmap <Leader>dk <Plug>VimspectorRestart
nmap <Leader>dh <Plug>VimspectorStepOut
nmap <Leader>dl <Plug>VimspectorStepInto
nmap <Leader>dj <Plug>VimspectorStepOver

function! s:Replace(...)
  let [l:repattern, l:dir] = split(a:1)
  let [l:pattern, l:replace] = split(l:repattern, "/")
  execute "vimgrep " . l:pattern . " " . l:dir
  set autowrite
  execute "silent! cdo %s/" . l:pattern . "/" . l:replace . "/g"
  set noautowrite
endfunction

"Custom Commands
command! -complete=file_in_path -nargs=1 Replace call s:Replace(<f-args>)

":vimgrep /pattern/ ./**/files              # results go to quickfix list
":set autowrite                             # auto-save when changing buffers
":silent! cdo %s/replaceme/replacement/gic  # cdo draws filenames from quickfix list
":set noautowrite
