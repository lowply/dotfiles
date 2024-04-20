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

run-ubuntu-noble:
	docker run -it --rm lowply/dotfiles:ubuntu-noble

run-ubuntu-jammy:
	docker run -it --rm lowply/dotfiles:ubuntu-jammy

run-ubuntu-focal:
	docker run -it --rm lowply/dotfiles:ubuntu-focal
