#
# ~/.osx
# sudo sh .osx
#

cd $HOME
cp -a .bash_profile{,.`date +%y%m%d`}
ln -s dotfiles/.bashrc .
ln -s dotfiles/.bash_profile .

if [ -x /usr/local/bin/brew ]; then
  brew install coreutils tmux gettext gnu-sed gnu-tar htop-osx wget nkf pidof keychain reattach-to-user-namespace tree watch colordiff pstree the_silver_searcher git tig hub ngrep
else
  echo "install xcode, command line tools, homebrew and hit .osx again!"
  exit 1;
fi

# disable dashboard
defaults write com.apple.dashboard mcx-disabled -boolean YES

# I like overlay scrollbars
defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"

# make ~/Library visible
chflags nohidden ~/Library

#
# Killall Apps
#
for app in Finder Dock SystemUIServer
do
  killall "$app" > /dev/null 2>&1
done

DATE=`date +%y%m%d`

#
# path setting
#
cd /etc
cp -a paths{,.$DATE}
echo "" > paths

echo "
/usr/local/bin
/usr/local/sbin
/usr/local/share/npm/bin
" >> /etc/paths.d/10-user

cat paths.$DATE >> /etc/paths.d/20-default

/usr/libexec/path_helper -s
