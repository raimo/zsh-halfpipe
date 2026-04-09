Output demo/demo.gif

Set FontSize 15
Set Width 1180
Set Height 560
Set Theme "Dracula"
Set Padding 24
Set Shell "zsh"
Set TypingSpeed 1ms

# ── hidden setup ──────────────────────────────────────────────────
Hide

Type `source /Users/raimo/workspace/pipeline-preview-zsh/halfpipe.zsh`
Enter
Sleep 50ms
Type `bindkey '^G' halfpipe-toggle-live-output`
Enter
Sleep 25ms

# fixed dates → deterministic hashes → predictable match counts per pattern
Type `export GIT_COMMITTER_DATE="2024-01-01T00:00:00" GIT_AUTHOR_DATE="2024-01-01T00:00:00"`
Enter
Sleep 25ms

Type `rm -rf /tmp/halfpipe-demo && mkdir /tmp/halfpipe-demo && cd /tmp/halfpipe-demo`
Enter
Sleep 25ms
Type `git init -q && git config user.email x@x.com && git config user.name Dev`
Enter
Sleep 25ms

Type `git commit --allow-empty -m 'fix: handle null pointer in token parser'`
Enter
Type `git commit --allow-empty -m 'feat: add streaming output support'`
Enter
Type `git commit --allow-empty -m 'fix: off-by-one error in range calculation'`
Enter
Type `git commit --allow-empty -m 'chore: update dependencies'`
Enter
Type `git commit --allow-empty -m 'feat: implement retry logic for failed requests'`
Enter
Type `git commit --allow-empty -m 'fix: memory leak when buffer overflows'`
Enter
Type `git commit --allow-empty -m 'feat: works on my machine README update'`
Enter
Type `git commit --allow-empty -m 'feat: add batch processing mode'`
Enter
Type `git commit --allow-empty -m 'fix: race condition in concurrent writes'`
Enter
Type `git commit --allow-empty -m 'refactor: extract auth middleware'`
Enter
Type `git commit --allow-empty -m 'feat: very demure, very mindful metrics endpoint'`
Enter
Type `git commit --allow-empty -m 'fix: incorrect timestamp formatting'`
Enter
Type `git commit --allow-empty -m 'test: add integration tests for parser'`
Enter
Type `git commit --allow-empty -m 'fix: handle unicode in file paths'`
Enter
Type `git commit --allow-empty -m 'feat: support environment variable expansion'`
Enter
Type `git commit --allow-empty -m 'feat: add rollback command for deploys'`
Enter
Type `git commit --allow-empty -m 'fix: prevent double submit in signup form'`
Enter
Type `git commit --allow-empty -m 'feat: cache expensive diff previews'`
Enter
Type `git commit --allow-empty -m 'feat: explain local setup shortcuts'`
Enter
Type `git commit --allow-empty -m 'feat: add dark launch feature flag wiring'`
Enter
Sleep 50ms

Type `clear`
Enter

Show

# ── demo ──────────────────────────────────────────────────────────
Sleep 150ms

# full command typed upfront — end of line means the last segment is editable
Set TypingSpeed 20ms
Type `git log --format=%s | grep -E "f[a]|:" | sed -E "s/feat/feat/" | tail -n 10`
Sleep 1200ms

# freeze after the third pipe, then edit only the tail count
Ctrl+G
Sleep 800ms
Backspace 1
Set TypingSpeed 30ms
Type `3`
Sleep 1200ms

# restore the full command
Ctrl+G
Sleep 400ms

# freeze at the sed segment and rewrite it so the previewed text changes
Left 15
Sleep 400ms
Ctrl+G
Sleep 800ms
Type `ure`
Sleep 1200ms
Backspace 3
Sleep 1200ms
Ctrl+G
Sleep 400ms

# freeze at the grep segment and widen, then narrow, the matches
Right 100
Left 41
Sleep 400ms
Ctrl+G
Sleep 800ms
Type `e`
Sleep 1200ms
Backspace 1
Sleep 1200ms
Ctrl+G
Sleep 300ms
Enter
Sleep 375ms
