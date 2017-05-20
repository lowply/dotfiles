# lowply/dotfiles

## Requirements

1. [Python3](https://www.python.org/downloads/) (make sure you have `python3` command in the `/usr/local/bin` dir)
1. [Neovim](https://neovim.io/)

## Install

```bash
$ cd
$ git clone https://github.com/lowply/dotfiles.git
$ ./dotfiles/bin/install.sh
```

## Post install

Install `diff-highlight` if necessary:

```
$ cd
$ git clone https://github.com/git/git.git
$ sudo cp -a git/contrib/diff-highlight/diff-highlight /usr/local/bin/diff-highlight
```

Install neovim pip module. Don't do `sudo pip3 install`, see [Why you shouldn't use sudo](https://github.com/zchee/deoplete-jedi/wiki/Setting-up-Python-for-Neovim#why-you-shouldnt-use-sudo)

```
$ pip3 install --user neovim
```

Install [dein.vim](https://github.com/Shougo/dein.vim):

```
$ cd
$ curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh
$ bash installer.sh ~/.cache/dein
$ rm installer.sh
```

Then type `vim`. Neovim starts up and installs all plugins. To make sure [deoplete](https://github.com/Shougo/deoplete.nvim) works as expected, run following in vim:

```
:UpdateRemotePlugins
```

To update vim plugins, run following in vim:

```
:call dein#update()
```
