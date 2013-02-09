#!/bin/sh

cd $HOME
mv .bashrc{,.`date +%y%m%d`}
mv .bash_profile{,.`date +%y%m%d`}

cd $HOME/dotfiles
dotfiles=`ls -a | egrep "^\." | egrep -v "git|osx|^\.\.$|^\.$"`

for dotfile in $dotfiles
do
    ln -Fis "$PWD/$dotfile" $HOME
done

if [ ! -d ~/.vim_tmp ]; then
    mkdir ~/.vim_tmp
fi

if [ ! -f ~/.bash_aliases ]; then
    touch ~/.bash_aliases
fi
