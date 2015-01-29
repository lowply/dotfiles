#!/bin/bash

export PATH=/usr/local/bin:$PATH
cd ~/dotfiles
git pull -q origin master && git submodule -q foreach git pull -q origin master
