
#
# read common bash settings
#

if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

#
# rbenv
#
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

#
# read OS specific alias settings
#

if [ -f ~/.bash_aliases ]; then
	. ~/.bash_aliases
fi
