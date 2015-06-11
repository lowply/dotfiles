#!/bin/bash

echo ""
for i in {0..255} ; do
	printf "\x1b[48;05;${i}m $(printf %03d ${i})"
	if [ $(((i + 1) % 16)) -eq 0 ]; then
		echo ""
	fi
done
echo ""
