build-ubuntu-noble:
	docker build . \
		-f Dockerfile.ubuntu-2404 \
		-t lowply/dotfiles:ubuntu-noble \

build-ubuntu-jammy:
	docker build . \
		-f Dockerfile.ubuntu-2204 \
		-t lowply/dotfiles:ubuntu-jammy \

build-ubuntu-focal:
	docker build . \
		-f Dockerfile.ubuntu-2004 \
		-t lowply/dotfiles:ubuntu-focal

# Docker defaults to xterm. Force to use the current TERM,
# otherwise tput doesn't work as expected
run-ubuntu-noble:
	docker run -it --rm -e TERM=${TERM} lowply/dotfiles:ubuntu-noble

run-ubuntu-jammy:
	docker run -it --rm -e TERM=${TERM} lowply/dotfiles:ubuntu-jammy

run-ubuntu-focal:
	docker run -it --rm -e TERM=${TERM} lowply/dotfiles:ubuntu-focal
