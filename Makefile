build-ubuntu:
	docker build . -f Dockerfile.ubuntu-2004 -t lowply/dotfiles:ubuntu-20.04
run-ubuntu:
	docker run -it --rm lowply/dotfiles:ubuntu-20.04
build-centos:
	docker build . -f Dockerfile.centos -t lowply/dotfiles:centos-8
run-centos:
	docker run -it --rm lowply/dotfiles:centos-8
