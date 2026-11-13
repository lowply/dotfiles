# lowply/dotfiles

Currently only supports macOS and Ubuntu.

## Install

```bash
$ cd /path/to/anywhere
$ git clone https://github.com/lowply/dotfiles.git
$ ./dotfiles/install.sh
```

Use `./dotfiles/install.sh -f` to replace existing symlinks with links to this checkout. Without `-f`, existing symlinks are skipped.

On macOS, install or update Homebrew packages separately with `./dotfiles/script/brew.sh`. Homebrew must already be installed.

## Karabiner-Elements

After editing `symlinks/.config/karabiner/assets/complex_modifications/lowply.json`, remove the affected rules in Karabiner-Elements Settings > Complex Modifications, then re-add them through Add predefined rule > @lowply's keymaps. Enabled rules are copied into the profile's `karabiner.json`, so updating the symlinked asset or restarting Karabiner-Elements does not update existing rules.

## Development

Use devcontainer