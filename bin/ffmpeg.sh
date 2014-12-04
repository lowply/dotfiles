#!/bin/bash

newfn=`echo $1 | sed -e "s/\.[^.]*$//"`
fn=$1
ffmpeg -i $fn -acodec libfaac -vcodec libx264 -threads 0 $newfn.mp4
