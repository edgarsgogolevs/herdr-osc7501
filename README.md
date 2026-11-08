# herdr-osc7501

Hermes plugin that reports status to [Herdr](https://herdr.dev) with
[OSC 7501](https://mitchellh.com/writing/program-status-osc7501), so a Hermes
session shows up in the agents list the way Claude Code does.

Herdr only lists a terminal whose program speaks that protocol. Hermes did
not. This plugin emits `idle`, `working`, `blocked`, and `done` from the
process that owns the terminal. Quitting clears the record. Hermes exits with
`os._exit`, which skips a normal exit handler, so the clear runs on the
shutdown path Hermes actually calls.

A remote agent is a Hermes process on that machine. Install the plugin there,
not only on the computer running the Herdr window.

## Install

On this computer:

```sh
hermes plugins install edgarsgogolevs/herdr-osc7501 --enable --yes-deps
```

On a machine from `hc machine ls`:

```sh
./install.sh arch
./install.sh --all
```

`install.sh` copies this folder to that machine's `~/.hermes/plugins` and
enables it. Restart Hermes after installing. A session that is already open
keeps the copy it started with.

## What it reports

| When | Status |
|---|---|
| Hermes is waiting at the prompt | idle |
| A turn is running | working |
| Approval, a question, or a sign-in | blocked |
| The turn finishes | done |
| Hermes quits, or the pane is closed | clear |

`done` stays until you look at the pane. Herdr turns it into idle.

## License

MIT
