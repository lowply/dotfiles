build-ubuntu:
	docker build . \
		-f Dockerfile.ubuntu-2204 \
		-t lowply/dotfiles:ubuntu-22.04 \
		-t lowply/dotfiles:latest

build-ubuntu-cs:
	docker build . \
		-f Dockerfile.ubuntu-2004 \
		-t lowply/dotfiles:ubuntu-20.04

run-ubuntu:
	docker run -it --rm lowply/dotfiles:ubuntu-22.04

run-ubuntu-cs:
	docker run -it --rm lowply/dotfiles:ubuntu-20.04
