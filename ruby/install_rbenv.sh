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
		if [ ! -x /usr/local/bin/git ]; then
			echo "Please install git first"
			exit 1
		else
			git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
			git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
		fi
		;;
	esac
fi

