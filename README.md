# lowply/dotfiles

Currently only supports macOS and Ubuntu.

## Install

```bash
$ cd /path/to/anywhere
$ git clone https://github.com/lowply/dotfiles.git
$ ./dotfiles/install.sh
```

## Visual Studio Code on macOS

After running the install script, manually symlink the `settings.json`:

```
ln -s ~/.vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
```
