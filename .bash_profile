#
# read common bash settings
#

if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

#
# read OS specific alias settings
#

if [ -f ~/.bash_aliases ]; then
	. ~/.bash_aliases
fi
