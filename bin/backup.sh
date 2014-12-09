#!/bin/bash

D=`date +%y%m%d_%H%M%S`; cp -a $1{,.${D}}; unset D
