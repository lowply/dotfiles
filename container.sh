#!/bin/bash

docker build . -t lowply/dotfiles
docker run --rm -it lowply/dotfiles /usr/bin/bash
