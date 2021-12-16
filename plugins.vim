" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.local/share/nvim/plugged')

Plug 'vim-airline/vim-airline'

Plug '/usr/share/fzf'
Plug 'junegunn/fzf.vim'

Plug 'tpope/vim-fugitive'

Plug 'airblade/vim-gitgutter'

Plug 'dracula/vim', { 'as': 'dracula' }

" Initialize plugin system
call plug#end()
