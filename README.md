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

I use [Kanary](https://kanary.to) for Eisuu/Kana switching and Karabiner-Elements only for Ctrl+HJKL arrow-key navigation.

The mappings in `symlinks/.config/karabiner/assets/complex_modifications/lowply.js` are combined into one JavaScript rule for the Apple Internal Keyboard and HHKB Studio. Run `./install.sh` to symlink it, then add it in Karabiner-Elements Settings > Complex Modifications > Add predefined rule > @lowply's keymaps. Alternatively, paste the file into Add your own rule using JavaScript.

When migrating from the JSON version, remove the old `~/.config/karabiner/assets/complex_modifications/lowply.json` symlink and the individual rules from your profile to avoid duplicate mappings.

After editing `lowply.js`, remove and re-add the combined rule. Karabiner-Elements stores a copy of the script in the profile's `karabiner.json`, so updating the symlinked asset or restarting Karabiner-Elements does not update the existing rule.

## Development

Use devcontainer