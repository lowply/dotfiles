
#
# read common bash settings
#

if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

#
# rbenv
#
if type rbenv > /dev/null 2>&1; then eval "$(rbenv init -)"; fi

#
# read OS specific alias settings
#

if [ -f ~/.bash_aliases ]; then
	. ~/.bash_aliases
fi
