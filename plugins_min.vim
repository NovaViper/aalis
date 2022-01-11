" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.local/share/nvim/plugged')

Plug 'vim-airline/vim-airline'

Plug 'tpope/vim-fugitive'

Plug 'airblade/vim-gitgutter'

" Initialize plugin system
call plug#end()
