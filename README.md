# pipeline-preview.zsh

`pipeline-preview.zsh` is an experimental Zsh widget that lets you preview the right-hand side of a pipeline against a cached snapshot of the left-hand side command.

When the widget is active, you can type a command such as:

```zsh
git status | grep modified
```

Press `Ctrl-G` while the cursor is on the command line:

- The command before the first `|` is executed once and cached.
- The command after the first `|` is re-run on each edit using the cached output.
- The source command is shown in cyan in the prompt predisplay.

This gives you a fast feedback loop while refining filters like `grep`, `sed`, `awk`, or `jq`.

## Status

This repository preserves the current prototype as a standalone plugin repo. It is useful for experimentation, but it still has rough edges:

- It only understands the first pipe character.
- It uses `eval`, so it should be treated as trusted-local-shell code only.
- Ctrl-C cleanup is still incomplete.
- Command output is cached only when live mode is first enabled.

## Installation

### Plain Zsh

Clone the repo somewhere on your machine and source the script from `.zshrc`:

```zsh
source /path/to/pipeline-preview.zsh
```

### Antigen

```zsh
antigen bundle <your-user>/pipeline-preview-zsh
```

### zinit

```zsh
zinit light <your-user>/pipeline-preview-zsh
```

## Usage

1. Type a pipeline with at least one `|`.
2. Press `Ctrl-G` to enable live preview.
3. Edit the right-hand side of the pipeline.
4. Press `Ctrl-G` again to stop live preview.
5. Press Enter to run the final command normally.

Example:

```zsh
ls -1 | grep zsh
```

Press `Ctrl-G`, then change `grep zsh` into `grep preview` or `wc -l` and watch the preview refresh below the prompt.

## Development

Syntax-check the script with:

```zsh
zsh -n pipeline-preview.zsh
```

The repo intentionally keeps the implementation in a single file so it can be sourced directly by shell plugin managers.
