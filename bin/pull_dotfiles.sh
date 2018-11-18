#!/bin/bash

export PATH=/usr/local/bin:$PATH
cd $(dirname $0) && cd ..
git pull -q origin master
