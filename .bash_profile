#
# functions
#

addpath(){
	if [ ! -d $1 ]; then
		echo "[addpath] \"$1\" does not exist."
		exit 1
	fi

	if [ ! -z "`echo $PATH | grep $1`" ]; then
		echo "[addpath] \"$1\" is already included in PATH"
		exit 1
	fi

	export PATH=$1:$PATH
}

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
