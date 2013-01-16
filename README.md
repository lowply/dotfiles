# lowply/dotfiles

- .vimrc for vim
- .vim for vim plugins/colorscheme (with [neobundle](https://github.com/Shougo/neobundle.vim) as a git submodule)
- .tmux.conf for [tmux](http://tmux.sourceforge.net/)
- Fixture.terminal for [Terminal.app](http://www.apple.com/macosx/apps/all.html#terminal) Theme
- symlink.sh as post-install script
- .gitignore, README

## how to use
    $ cd
    $ git clone --recursive git://github.com/lowply/dotfiles.git
    $ sh dotfiles/symlink.sh
    $ vim
    :NeoBundleInstall
    -> restart vim

- don't forget to make [vimproc](https://github.com/Shougo/vimproc) on your system
- Fixture.terminal is a theme for Terminal.app. Just double click in Finder.
It uses [Ricty](http://save.sys.t.u-tokyo.ac.jp/~yusa/fonts/ricty.html) font.
enjoy :)
