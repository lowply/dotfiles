#!/bin/sh
cd $(dirname $0)
for dotfile in .?*
do
    if [ $dotfile != '..' ] && [ $dotfile != '.git' ]
    then
        ln -Fis "$PWD/$dotfile" $HOME
    fi
done

cd $HOME
if [ ! -d .vim_backup ];then mkdir .vim_backup;fi
if [ ! -d .vim_swap ];then mkdir .vim_swap;fi
