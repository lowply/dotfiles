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
		yum -y --enablerepo=epel install xmlto asciidoc docbook2X
		cd /usr/local/bin
		ln -s /usr/bin/db2x_docbook2texi docbook2x-texi
		ln -s /usr/bin/db2x_docbook2man docbook2x-man
		make prefix=/usr/local/git install install-doc install-html install-info

		mkdir -p /usr/local/git/contrib/completion
		cd /usr/local/git/contrib/completion
		wget --no-check-certificate https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
		wget --no-check-certificate https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
	else
		echo "you need to be root"
		exit 1
	fi
	;;
esac

