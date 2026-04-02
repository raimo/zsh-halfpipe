# zsh-halfpipe

`zsh-halfpipe` is an experimental Zsh widget that lets you preview the final stage of a pipeline against a cached snapshot of the earlier pipeline stages.

When the widget is active, you can type a command such as:

```zsh
git status | grep modified
```

Press `Ctrl-G` while the cursor is on the command line:

- Everything before the last unquoted `|` is executed once and cached.
- The command after the last unquoted `|` is re-run on each edit using the cached output.
- The source command is shown in cyan in the prompt predisplay.
- Press `Ctrl-X Ctrl-G` while preview mode is active to refresh the cached source output.

This gives you a fast feedback loop while refining filters like `grep`, `sed`, `awk`, or `jq`.

## Status

This repository preserves the current prototype as a standalone plugin repo. It is useful for experimentation, but it still has rough edges:

- Preview commands run in a `zsh -fc` subprocess that is hydrated with your current aliases and functions.
- It temporarily takes over `Ctrl-G` while a previewable pipeline is on the command line, then restores the previous binding when preview mode exits.
- It temporarily binds `Ctrl-X Ctrl-G` while preview mode is active so you can refresh the cached upstream output.
- Command output is cached only when live mode is first enabled.

## Installation

### Plain Zsh

Clone the repo somewhere on your machine and source the script from `.zshrc`:

```zsh
git clone https://github.com/raimo/zsh-halfpipe.git
source /path/to/zsh-halfpipe/halfpipe.zsh
```

### Antigen

```zsh
antigen bundle raimo/zsh-halfpipe
```

### zinit

```zsh
zinit light raimo/zsh-halfpipe
```

## Usage

1. Type a pipeline with at least one unquoted `|`.
2. Press `Ctrl-G` to enable live preview.
3. Edit the final pipeline stage.
4. Press `Ctrl-X Ctrl-G` if you want to refresh the cached upstream output.
5. Press `Ctrl-G` again to stop live preview.
6. Press Enter to run the final command normally.

Example:

```zsh
ls -1 | grep zsh
```

Press `Ctrl-G`, then change `grep zsh` into `grep preview` or `wc -l` and watch the preview refresh below the prompt.

## Development

Syntax-check the script with:

```zsh
zsh -n halfpipe.zsh
```

Run the plugin test suite with:

```zsh
zsh tests/run.zsh
```

Mutation-check the test harness with:

```zsh
zsh tests/test-the-test.zsh
```

The repo intentionally keeps the implementation in a single file so it can be sourced directly by shell plugin managers.
