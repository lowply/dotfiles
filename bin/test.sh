#!/bin/bash

if mysql --version | grep "Distrib 5.5" > /dev/null ; then
	echo "yes"
else
	echo "no"
fi

