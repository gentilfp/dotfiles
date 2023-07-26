echo 'Creating symbolic links...'

ln -sf `realpath`/.tmux.conf ~/.tmux.conf
ln -sf `realpath`/gentil.zsh-theme ~/.oh-my-zsh/themes/gentil.zsh-theme
ln -sf `realpath`/init.vim ~/.config/nvim/init.vim

echo 'Done'

