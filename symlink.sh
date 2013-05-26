#!/bin/sh

cd $(dirname $0)
dotfiles=`ls -A | grep "^\." | grep -v "^\.git"`

for dotfile in $dotfiles
do
  ln -Fis "$PWD/$dotfile" $HOME
done

if [ ! -d ~/.vim_tmp ]; then
    mkdir ~/.vim_tmp
fi
