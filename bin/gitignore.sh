#!/bin/bash

. $(dirname $0)/lib.sh

IGNORE_LIB="${HOME}/src/github.com/github/gitignore"
IGNORE_PATH="${HOME}/dotfiles/symlinks/.config/git/ignore"

LIST="
	Global/macOS.gitignore
	Global/Linux.gitignore
	Global/Vim.gitignore
	Global/Dropbox.gitignore
	Node.gitignore
	Ruby.gitignore
	Go.gitignore
"

[ -d ${IGNORE_LIB} ] || abort "Please clone github/gitignore to ${IGNORE_LIB}"

echo "" > ${IGNORE_PATH}

for FILE in ${LIST}
do
	echo "" >> ${IGNORE_PATH}
	echo "##### ${FILE}" >> ${IGNORE_PATH}
	echo "" >> ${IGNORE_PATH}
	cat ${IGNORE_LIB}/${FILE} >> ${IGNORE_PATH}
done
