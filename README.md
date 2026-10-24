<p align="center"><img src="logo.svg" alt="macOS ASCII logo" width="300"></p>

# Neofetch for macOS

macOS fork of [Neofetch](https://github.com/dylanaraps/neofetch) by Dylan Araps, maintained by **ismqo**. Shows OS, CPU, memory, disk, shell and local IP information.
Requires macOS and Bash 3.2+.

## Install / uninstall

Run from this repository:

```sh
sudo make install       # installs the command and man page under /usr/local
sudo make uninstall     # also deletes your ~/.config/neofetch and its backups
```

With `sudo`, cleanup targets the invoking user's default config directory.
Custom `XDG_CONFIG_HOME` directories and backups beside custom `--config` files
need manual cleanup.

## Usage

Use `neofetch` after installation, or `./neofetch` from this directory:

```sh
neofetch                                        # Apple logo + system summary
neofetch --stdout                               # plain text, no artwork
neofetch --json                                 # JSON, no artwork
neofetch uptime cpu                             # selected fields only
neofetch --customize                            # show/hide, reorder and rename fields
neofetch --ascii "$HOME/Pictures/my-art.txt"    # custom ASCII logo
neofetch --off                                  # hide the logo
neofetch --gap 5                                # spacing between logo and information
neofetch --config /path/to/config.conf          # load a trusted Bash config
```

More options: `neofetch --help` or `man neofetch`.

## Custom ASCII

Use trusted text files with at least two lines; single-line art falls back to the
Apple logo. Backslashes are interpreted as escapes: write `\\` for a literal `\`.
Optional color placeholders: `${c1}` through `${c6}`. PNG/JPEG images are unsupported.

To keep custom art, set these in `~/.config/neofetch/config.conf`
(or `$XDG_CONFIG_HOME/neofetch/config.conf` when set):

```sh
image_backend="ascii"
image_source="$HOME/Pictures/my-art.txt"
```

## License

Licensed under [MIT](LICENSE.md).
