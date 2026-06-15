---
title: Configuration
---

# Configuration

Circle CLI reads its settings from your repository's git config and a couple of
environment variables. It does not use a global dotfile — configuration is
per-repository, which keeps tokens and project mappings scoped to the project
they belong to.

## Token

Commands that talk to CircleCI need a personal API token. It is resolved in this
order:

1. Git config `circleci.token` (set by `circle login` or `circle token <value>`).
2. The `CIRCLE_CLI_TOKEN` environment variable.

```
# Stored in .git/config (local to this repo)
$ circle token <your-token>

# Or supply it via the environment (handy for CI/scripts)
$ export CIRCLE_CLI_TOKEN=<your-token>
```

An empty value is treated as "not set". If no token is found, commands that need
one print a hint to run `circle login`.

> **Security:** never commit a token. Prefer `CIRCLE_CLI_TOKEN` in automated
> environments and store it as a secret, not in source.

## Project slug

API v2 commands (`pipelines`, and the live `dashboard` path) address a project
by its slug, in the form `vcs/org/project` (for example `gh/circle-cli/circle-cli`).
The slug is resolved in this order:

1. The `CIRCLE_CLI_PROJECT_SLUG` environment variable.
2. Git config `circleci.project-slug`.
3. Inference from the `origin` remote URL.

When inferring, the VCS prefix is chosen from the remote host:

| Remote host | Slug prefix |
| --- | --- |
| `github.com` | `gh` |
| `bitbucket.org` | `bb` |
| anything else | `gh` (fallback) |

To override inference (for example, mirrored or self-hosted remotes):

```
$ git config circleci.project-slug gh/my-org/my-project
# or
$ export CIRCLE_CLI_PROJECT_SLUG=gh/my-org/my-project
```

## Repository selection

By default every command operates on the git repository in the current
directory. Use `--repo` to point elsewhere:

```
$ circle status --repo ~/code/some-project
```

The classic (v1) commands currently support GitHub-hosted repositories; other
hosts will be rejected.

## API endpoint

The API v2 client targets `https://circleci.com/api/v2`. There is no
user-facing setting for this today; it is a constant in the client.
