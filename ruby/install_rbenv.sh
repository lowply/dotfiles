#!/bin/bash

if [ -d ~/.rbenv ]; then
	echo "rbenv is already installed"
else
	case "${OSTYPE}" in
	darwain*)
		echo "darwin"
		if [ ! -x /usr/local/bin/brew ]; then
			echo "Please install homebrew first"
			exit 1
		else
			brew update && brew install rbenv ruby-build
		fi
		;;
	linux*)
		echo "linux"
		RUBY_VERSION="2.1.2"

		if type git > /dev/null 2>&1; then GITINSTALLPATH=$(which git); fi
		if [ -z "$GITINSTALLPATH" ]; then
			echo "Please install git first"
			exit 1
		else
			git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
			git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
			rbenv install ${RUBY_VERSION}
			rbenv global ${RUBY_VERSION}
			rbenv rehash
		fi
		unset RUBY_VERSION
		unset GITINSTALLPATH
		;;
	esac
fi

