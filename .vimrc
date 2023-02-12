" Run :PlugInstall in a new machine
call plug#begin('~/.vim/colors/')
Plug 'kaicataldo/material.vim', { 'branch': 'main' }
call plug#end()

let g:material_theme_style = 'ocean'
colorscheme material
