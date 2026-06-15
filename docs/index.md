---
title: Circle CLI
---

# Circle CLI

Command line tools for [CircleCI](https://circleci.com), without leaving your
terminal. Check build status, trigger and cancel builds, watch a run live, and
browse a modern pipeline dashboard — all from your shell.

```
$ gem install circle-cli
$ circle login
$ circle
```

## Documentation

- [Quickstart](quickstart.md) — install, authenticate, and run your first command.
- [Commands](commands.md) — every command, what it does, and its options.
- [Configuration](configuration.md) — tokens, project slugs, and environment variables.
- [CI dogfood](ci-dogfood.md) — how circle-cli tests itself on CircleCI.
- [Migration](migration.md) — what's changing in the modernized CLI.
- [Contributing](contributing.md) — local development and how to send a patch.

## Status

This is an actively modernizing project. The classic v1-based commands
(`status`, `build`, `cancel`, `open`, `overview`) work today. Newer API v2
commands (`me`, `pipelines`) and the `dashboard` TUI are landing
incrementally — see the [migration notes](migration.md) for what is finished
versus on the roadmap.

The source for this site lives in the [`docs/` folder of the
repository](https://github.com/circle-cli/circle-cli/tree/master/docs).
