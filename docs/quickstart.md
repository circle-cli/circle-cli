---
title: Quickstart
---

# Quickstart

## 1. Install

```
$ gem install circle-cli
```

This installs the `circle` executable.

## 2. Authenticate

Most commands talk to CircleCI on your behalf and need a personal API token.
The interactive flow opens the token page for you:

```
$ circle login
```

It walks you through creating a token on CircleCI, then prompts you to paste it
back. The token is stored in your repository's git config under
`circleci.token`.

If you already have a token, you can set it directly:

```
$ circle token <your-token>
```

See [Configuration](configuration.md) for all the ways a token can be supplied
(including the `CIRCLE_CLI_TOKEN` environment variable).

> The `dashboard --sample` command and `circle help` are the only commands that
> work with no token at all — handy for trying the CLI out.

## 3. Run your first command

From inside a git repository whose `origin` remote points at a CircleCI-backed
project:

```
# Build status for the HEAD of your current branch
$ circle

# Watch the latest build, refreshing as it runs
$ circle --watch

# List recent builds across all branches
$ circle overview

# Preview the new pipeline dashboard with bundled sample data
$ circle dashboard --sample
```

## 4. Explore

```
$ circle help            # list every command
$ circle help status     # detailed help for one command
```

Continue to the full [command reference](commands.md).
