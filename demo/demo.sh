#!/bin/sh

# For initializing test data to capture GIF video demo

rm -rf /tmp/halfpipe-demo && mkdir /tmp/halfpipe-demo && cd /tmp/halfpipe-demo
git init -q && git config user.email x@x.com && git config user.name Dev

git commit --allow-empty -m 'fix: handle null pointer in token parser'
git commit --allow-empty -m 'feat: add streaming output support'
git commit --allow-empty -m 'fix: off-by-one error in range calculation'
git commit --allow-empty -m 'fix: update dependencies'
git commit --allow-empty -m 'feat: implement retry logic for failed requests'
git commit --allow-empty -m 'fix: memory leak when buffer overflows'
git commit --allow-empty -m 'feat: works on my machine README update'
git commit --allow-empty -m 'feat: add batch processing mode'
git commit --allow-empty -m 'fix: race condition in concurrent writes'
git commit --allow-empty -m 'fix: extract auth middleware'
git commit --allow-empty -m 'feat: very demure, very mindful metrics endpoint'
git commit --allow-empty -m 'fix: incorrect timestamp formatting'
git commit --allow-empty -m 'fix: add integration tests for parser'
git commit --allow-empty -m 'fix: handle unicode in file paths'
git commit --allow-empty -m 'feat: support environment variable expansion'
git commit --allow-empty -m 'feat: add rollback command for deploys'
git commit --allow-empty -m 'fix: prevent double submit in signup form'
git commit --allow-empty -m 'feat: cache expensive diff previews'
git commit --allow-empty -m 'feat: explain local setup shortcuts'
git commit --allow-empty -m 'feat: add dark launch feature flag wiring'
