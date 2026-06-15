---
title: Commands
---

# Commands

Run `circle help` to list commands and `circle help <command>` for details on
any one. Every command accepts the global `--repo` option:

| Option | Default | Description |
| --- | --- | --- |
| `--repo=PATH` | `.` | Path to the git repository to operate on. |

The default command is `status`, so running `circle` with no arguments is the
same as `circle status`.

---

## status

`circle status` — show the CircleCI build result for the HEAD of your current
branch. This is the default command (`circle` alone runs it).

| Option | Default | Description |
| --- | --- | --- |
| `--branch=NAME` | current branch | Branch to report on. |
| `--watch` | `false` | Re-render as the build progresses. |
| `--poll=SECONDS` | `5` | Polling frequency when watching. |

```
$ circle
$ circle --watch
$ circle status --branch main
```

Exits non-zero when the build has failed, which makes it usable in scripts.

## watch

`circle watch` — alias for `circle --watch`.

## overview

`circle overview` — list recent builds and their statuses across all branches.

| Option | Default | Description |
| --- | --- | --- |
| `--watch` | `false` | Re-render the list as builds progress. |
| `--poll=SECONDS` | `5` | Polling frequency when watching. |

## build

`circle build` — trigger a new build on CircleCI for your current branch, then
start watching its status.

| Option | Default | Description |
| --- | --- | --- |
| `--branch=NAME` | current branch | Branch to build. |

## cancel

`circle cancel` — cancel the most recent build for your current branch.

| Option | Default | Description |
| --- | --- | --- |
| `--branch=NAME` | current branch | Branch whose latest build to cancel. |

## open

`circle open` — open the latest build's results page in your browser.

| Option | Default | Description |
| --- | --- | --- |
| `--branch=NAME` | current branch | Branch whose build to open. |

## dashboard

`circle dashboard` — render a modern CircleCI pipeline dashboard in the
terminal, showing pipelines, their workflows, and per-job status.

| Option | Default | Description |
| --- | --- | --- |
| `--sample` | `false` | Render bundled sample data; no repo or token needed. |
| `--color` / `--no-color` | `true` | Toggle ANSI color output. |
| `--unicode` / `--no-unicode` | `true` | Toggle unicode icons and box drawing. |
| `--width=N` | terminal width | Override the render width (columns). |
| `--branch=NAME` | all branches | Limit live pipelines to a branch. |

```
$ circle dashboard --sample
$ circle dashboard --sample --no-color --width 80
$ circle dashboard --branch main
```

Without `--sample`, the dashboard reads live CircleCI API v2 pipeline,
workflow, and job data for the resolved project slug. It requires a configured
token.

## tui

`circle tui` — alias for `circle dashboard`.

## token

`circle token [VALUE]` — save a CircleCI token, or report token status.

- `circle token` reports whether a token is configured and where it came from;
  it does **not** print the secret value.
- `circle token --show` prints the token value explicitly. Use sparingly.
- `circle token <value>` stores `<value>` in git config under `circleci.token`.

For an interactive flow that opens CircleCI's token page, use `circle login`.

## login

`circle login` — interactive token setup. Opens the CircleCI token page,
prompts you to paste a new token, stores it, and validates it with CircleCI
without echoing the value.

## me

`circle me` — show the current CircleCI user. Uses the API v2 `/me` endpoint and
requires a configured token.

> **New in the modernized CLI.**

## projects

`circle projects` — show the resolved project slug for the current repository
and list collaborations visible to the token.

| Option | Default | Description |
| --- | --- | --- |
| `--json` | `false` | Emit machine-readable JSON. |

> **New in the modernized CLI.**

## pipelines

`circle pipelines` — list recent pipelines for this project using the API v2.
Requires a configured token.

| Option | Default | Description |
| --- | --- | --- |
| `--branch=NAME` | all branches | Filter pipelines to a branch. |

> **New in the modernized CLI.**

## workflows

`circle workflows PIPELINE_ID` — list workflows for a pipeline using the API v2.
Requires a configured token.

> **New in the modernized CLI.**

## jobs

`circle jobs WORKFLOW_ID` — list jobs for a workflow using the API v2. Requires a
configured token.

> **New in the modernized CLI.**
