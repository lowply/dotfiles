#!/bin/sh


_tarbw=10
_date=`date +\%y\%m\%d_%H%M`

function puts(){
  echo -e "$1" >> sample.txt
}

function bwtar(){
  tar czf - $1 | cstream -t $(($_tarbw*1024*1024)) -T 2 > $1.$_date.tar.gz
  rm -rf $1
}
