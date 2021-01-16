# lowply/dotfiles

## Install

```bash
$ cd /path/to/anywhere
$ git clone https://github.com/lowply/dotfiles.git
$ ./dotfiles/install do
```

## Visual Studio Code

After running the install script, manually symlink the `settings.json`:

```
ln -s ~/.vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
```

## Development

Running a test in a container:

```
docker run -v $(pwd):/root/dotfiles -it --rm centos:latest /bin/bash
```
