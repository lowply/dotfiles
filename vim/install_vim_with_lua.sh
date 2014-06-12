#!/bin/bash

case "${OSTYPE}" in
darwin*)
	if type brew > /dev/null 2>&1; then
		brew install vim --with-lua
	else
		echo "Please install homebrew and run again"
	fi
;;
linux*)
	if [ ! "${USER}" == "root" ]; then
		echo "You should be root"
		exit 1
	fi
	yum -y remove vim*
	yum -y install lua lua-devel mercurial
	cd /usr/local/src
	hg clone https://vim.googlecode.com/hg/ vim
	cd vim
	./configure --prefix=/usr/local/vim --with-features=huge --enable-multibyte --enable-luainterp --enable-fail-if-missing
	make && make install
	cd /usr/local/bin
	ln -s /usr/local/vim/bin/vim .
;;
esac
