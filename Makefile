build:
	docker build . -t lowply/dotfiles:ubuntu-20.04
run:
	docker run -it --rm lowply/dotfiles:ubuntu-20.04
