#!/bin/bash

if [ ! "${USER}" == "root" ]; then
	echo "You should be root"
	exit 1
fi

if type go > /dev/null 2>&1; then GOINSTALLPATH=$(which go); fi

if [ -z "$GOINSTALLPATH" ]; then
	case "${OSTYPE}" in
	darwin*)
		echo "brew update && brew install go"
	;;
	linux*)
		DISTLINK_122_64="https://storage.googleapis.com/golang/go1.2.2.linux-amd64.tar.gz"
		cd /usr/local/src
		wget --no-check-certificate $DISTLINK_122_64
		tar vxzf go1.2.2.linux-amd64.tar.gz
		mv go /usr/local/
		cd /usr/local/bin
		ln -s /usr/local/go/bin/* .
	;;
	esac
else
	echo "go is already installed"
fi

unset GOINSTALLPATH

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
esac
ln -Fis $HOME/go/src/github.com/nsf/gocode/vim gocode

