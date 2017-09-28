# lowply/dotfiles

## Install

```bash
$ cd
$ git clone https://github.com/lowply/dotfiles.git
$ ./dotfiles/bin/install.sh
```

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
