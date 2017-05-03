#!/bin/bash

for C in {0..255}; do
    tput setab $C
    echo -n "$C "
done
tput sgr0
echo
