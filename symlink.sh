#!/bin/bash

cd $(dirname $0)
DOTFILES=`ls -A | grep "^\." | egrep -v "^\.gitignore$|^\.gitmodules$|^\.git$"`
DATE=$(date +%y%m%d)

if [ -r ~/.bash_profile -a ! -L ~/.bash_profile ]; then
	mv ~/.bash_profile ~/.bash_profile.$DATE	
fi

if [ ! -r ~/.bash_aliases ]; then
	touch ~/.bash_aliases
fi

if [ ! -d ~/.vim_tmp ]; then
	mkdir ~/.vim_tmp
fi

for DOTFILE in $DOTFILES
do
	ln -Fis "$PWD/$DOTFILE" $HOME
done
