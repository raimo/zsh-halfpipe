# zsh-halfpipe

Press `Ctrl-G` on any pipeline and the output updates live as you edit the last command.

```zsh
git log --oneline | grep -E "fix"
```

Hit `Ctrl-G`. Now refine the regex — change it to `"fix|feat"`, then `"^[a-f0-9]+ (fix|feat):"` — and see what matches instantly. The left side runs once; you iterate on the right without re-running `git log`.

Great for getting a regular expression right without executing the full pipeline on every attempt.

- The upstream command is cached on activation and shown in cyan.
- Press `Ctrl-X Ctrl-G` to re-run the upstream and refresh the cache.
- Press `Ctrl-G` again to exit. Press `Enter` to run the final command normally.

## How it works

- Preview commands run in a `zsh -fc` subprocess hydrated with your current aliases and functions.
- `Ctrl-G` is borrowed while a pipeline is on the command line and restored when you exit.
- `Ctrl-X Ctrl-G` is bound while preview mode is active and released on exit.
- Output is cached when you first activate preview. Use `Ctrl-X Ctrl-G` to refresh it.

## Installation

### Manual (recommended — no plugin manager required)

This works whether you're using plain Zsh, Oh My Zsh, or any other setup.

```zsh
mkdir -p ~/.local/share
git clone https://github.com/raimo/zsh-halfpipe.git ~/.local/share/zsh-halfpipe
```

Then add this line to your ~/.zshrc:

```zsh
source ~/.local/share/zsh-halfpipe/halfpipe.zsh
```

### Oh My Zsh

```zsh
git clone https://github.com/raimo/zsh-halfpipe.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-halfpipe
```

Then add zsh-halfpipe to your plugins array in ~/.zshrc:

```zsh
plugins=(git zsh-halfpipe …)
```

### With plugin managers

#### zinit

```zsh
zinit light raimo/zsh-halfpipe
```

#### Antigen

```zsh
antigen bundle raimo/zsh-halfpipe
```

#### Any other manager that can source a single .zsh file should work too (the repo is deliberately kept to one file for this reason).

## Uninstallation

Just remove the source line (or the plugin name from the plugins= array) and delete the cloned directory.

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
