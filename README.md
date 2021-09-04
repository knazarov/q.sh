# CLI to answer natural language questions

`q.sh` is a command-line tool that allows you to interact with your
computer using natural language.

Example usage:

```sh
export Q_SCRIPT_DIR=`pwd`

./q 2.0 kg in pounds
4.41

./q 1 pounds in kg
0.45

./q random number 1-100
53
```

## Extending q.sh

You can extend `q.sh` using any programming language. In order to do so, you
need to place an executable file starting with `q-` in `Q_SCRIPT_DIR`
(by default, ~/.config/q.sh).

When called without parameters, your script should return a newline-separated
list of regular expressions that match strings it's interested in.

When called with an argument, this argument will always be what it expects to
get as input. `q.sh` will take care of dispatching the calls properly.

To get an idea how it works, you can stury `q-weight-convert` and `q-random-number`
that are located in this repository.

## License

Distributed under the terms of the BSD License
