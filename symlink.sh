#!/bin/sh

cd $HOME/dotfiles
dotfiles=`ls -a | egrep "^\." | egrep -v "git|osx|^\.\.$|^\.$"`

for dotfile in $dotfiles
do
    ln -Fis "$PWD/$dotfile" $HOME
done

if [ ! -d ~/.vim_tmp ]; then
    mkdir ~/.vim_tmp
fi
