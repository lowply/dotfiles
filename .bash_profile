
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

# The next line updates PATH for the Google Cloud SDK.
source /Users/sho/google-cloud-sdk/path.bash.inc

# The next line enables bash completion for gcloud.
source /Users/sho/google-cloud-sdk/completion.bash.inc
