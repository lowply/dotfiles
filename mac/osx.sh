#
# ~/.osx
# sudo sh .osx
#

cd $HOME

# disable dashboard
defaults write com.apple.dashboard mcx-disabled -boolean true

# I like overlay scrollbars
defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"

# make ~/Library visible
chflags nohidden ~/Library

# disable shadow in screen shot
defaults write com.apple.screencapture disable-shadow -boolean true

#
# Killall Apps
#
for app in Finder Dock SystemUIServer
do
  killall "$app" > /dev/null 2>&1
done
