#!/bin/bash

GOINSTALLPATH=$(which go)

if [ -x "$GOINSTALLPATH" ]; then
	#
	# gopath dir
	#
	if [ ! -d $HOME/go ]; then
		mkdir $HOME/go
	fi

	#
	# gocode
	#
	go get github.com/nsf/gocode
	go get code.google.com/p/go.tools/cmd/godoc

	#
	# vim
	#
	cd $HOME/.vim/bundle/
	case "${OSTYPE}" in
	darwin*)
		ln -Fis /usr/local/opt/go/libexec/misc/vim go
	;;
	linux*)
		ln -Fis /usr/local/go/misc/vim go
	;;
	ln -Fis $HOME/go/src/github.com/nsf/gocode/vim gocode
fi
