<p align="center"><img src="logo.svg" alt="macOS ASCII logo" width="300"></p>

# Neofetch for macOS 

A command-line system information tool for macOS, written in Bash 3.2+.

This is a variation of [Neofetch](https://github.com/dylanaraps/neofetch)
by Dylan Araps, focused on macOS. It runs on the Bash that ships with macOS,
needs no extra packages and makes no network requests. On any other
operating system it exits with an error.

## Usage

```sh
./neofetch              # logo + system summary
./neofetch --stdout     # plain text
./neofetch --json       # JSON output
./neofetch uptime cpu   # only these fields
```

See `neofetch --help` or `man neofetch` for all options.

## Install

```sh
sudo make install       # /usr/local/bin and /usr/local/share/man
sudo make uninstall     # also removes ~/.config/neofetch (config and its .bak)
```

`make uninstall` removes the per-user config of the user who ran `sudo`. If you
set a custom `XDG_CONFIG_HOME`, `sudo` drops it; remove `$XDG_CONFIG_HOME/neofetch`
by hand. A `.bak` written next to a file passed with `--config` is not removed.

## License

MIT. See [LICENSE.md](LICENSE.md).
