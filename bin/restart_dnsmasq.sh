#!/bin/bash

echo ${OSTYPE} | grep "darwin" || { echo "Not a Mac OS"; exit 1; }

ps auxw | grep [s]bin/dnsmasq
sudo launchctl unload -w /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
sudo launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
ps auxw | grep [s]bin/dnsmasq
sudo dscacheutil -flushcache
