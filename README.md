# q.sh: a fuzzy launcher based on fzf

`q.sh` is a launcher for tiling window managers, that can not only run regular binaries,
but also execute prefix commands.

## Extending q.sh

You can extend `q.sh` using any programming language. In order to do so, you
need to place an executable file starting with `q-` in `Q_SCRIPT_DIR`
(by default, ~/.config/q.sh).

To see an example of how to write a `q.sh` extension, take a look at `q-pass`.

## License

Distributed under the terms of the BSD License
