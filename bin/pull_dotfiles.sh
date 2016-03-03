#!/bin/bash

export PATH=/usr/local/bin:$PATH
cd ~/dotfiles
# not using submodules anymore
# git pull -q origin master && git submodule -q foreach git pull -q origin master
git pull -q origin master
