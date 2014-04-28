#
# functions
#

addpath(){
	if [ ! -d $1 ]; then
		echo "[addpath] \"$1\" does not exist."
	fi

	if [ ! -z "`echo $PATH | grep $1`" ]; then
		echo "[addpath] \"$1\" is already included in PATH"
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

# The next line updates PATH for the Google Cloud SDK.
source /Users/sho/google-cloud-sdk/path.bash.inc

# The next line enables bash completion for gcloud.
source /Users/sho/google-cloud-sdk/completion.bash.inc
