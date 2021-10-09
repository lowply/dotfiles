vim_version = "8.2.3483"

build-ubuntu:
	docker build . \
		-f Dockerfile.ubuntu-2004 \
		--build-arg VIM_VER=$(vim_version) \
		-t lowply/dotfiles:ubuntu-20.04

build-centos:
	docker build . \
		-f Dockerfile.centos \
		--build-arg VIM_VER=$(vim_version) \
		-t lowply/dotfiles:centos-8

build-archlinux:
	docker build . \
		-f Dockerfile.archlinux \
		--build-arg VIM_VER=$(vim_version) \
		-t lowply/dotfiles:archlinux

run-ubuntu:
	docker run -it --rm lowply/dotfiles:ubuntu-20.04

run-centos:
	docker run -it --rm lowply/dotfiles:centos-8

run-archlinux:
	docker run -it --rm lowply/dotfiles:archlinux
