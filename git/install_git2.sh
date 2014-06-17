#!/bin/bash

# need to be root

case "${OSTYPE}" in
darwin*)
	echo "brew update && brew install git"
	;;
linux*)
	if [ "${USER}" = "root" ]; then
		cd /usr/local/src
		wget https://www.kernel.org/pub/software/scm/git/git-2.0.0.tar.gz
		tar vxzf git-2.0.0.tar.gz
		cd git-2.0.0
		yum -y --enablerepo=epel install xmlto asciidoc docbook2x
		cd /usr/local/bin
		ln -s docbook2x-texi /usr/bin/db2x_docbook2texi
		ln -s docbook2x-man /usr/bin/db2x_docbook2man
		make prefix=/usr/local/git install install-doc install-html install-info
	else
		echo "you need to be root"
		exit 1
	fi
	;;
esac

