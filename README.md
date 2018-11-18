# lowply/dotfiles

## Install

```bash
$ cd /path/to/anywhere
$ git clone https://github.com/lowply/dotfiles.git
$ ./dotfiles/install do
```

If you use [ghq](https://github.com/motemen/ghq) for repository management, dotfiles will be stored in `~/.ghq/github.com/lowply/dotfiles`

## Post install - macOS

Install [Homebrew](https://brew.sh/), `brew tap Homebrew/bundle` and run:

```
$ cd ~/dotfiles && brew bundle
```

- Don't forget `diff-highlight`
- Make sure you have `python3` in `/usr/local/bin`
- `pip3 install neovim` for [neovim](https://neovim.io/)
- [dein.vim](https://github.com/Shougo/dein.vim) for neovim  
- [Docker for Mac](https://www.docker.com/docker-mac)

## Post install - CentOS

See [lowply/kickstart](https://github.com/lowply/kickstart/) for install scripts.

## Development

Running a test in a container:

```
docker run -v $(pwd):/root/dotfiles -it --rm centos:latest /bin/bash
```
