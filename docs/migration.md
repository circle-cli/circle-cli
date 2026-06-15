---
title: Migration
---

# Migration & modernization

Circle CLI is moving from the legacy CircleCI v1 API toward a native CircleCI
**API v2** integration. This page tracks what has landed and what is still on
the roadmap, so you know which commands are finished features versus
work-in-progress.

## What changed

- **Ruby 3.3 is now required** (see `.ruby-version` and the gemspec). Older
  Rubies are no longer supported.
- **A native API v2 client** (`Circle::CLI::ApiClient`) was added, built on
  `Net::HTTP` from the standard library — no external SDK. It handles token
  auth, JSON, error formatting, and `next_page_token` pagination.
- **New v2 commands** were introduced: `circle me` and `circle pipelines`.
- **A modern terminal dashboard** (`circle dashboard`) renders pipelines,
  workflows, and jobs.

## Status at a glance

| Area | Status |
| --- | --- |
| `status`, `build`, `cancel`, `open`, `overview` (v1) | Working |
| `token`, `login` | Working |
| `me`, `pipelines` (v2) | Working (require a token) |
| `dashboard --sample` | Working |
| `dashboard` with live data | **Roadmap** — not wired up yet |

## Dashboard: sample vs live

The dashboard ships now because its data source is behind an adapter seam. The
`--sample` path renders bundled fixture data and works with no repo or token.

The **live** path — reading real pipelines/workflows/jobs from the CircleCI
v2 API and mapping them into the renderer's shape — is not implemented yet.
Running `circle dashboard` without `--sample` will report that live data is
pending and point you at `--sample`. This is intentional: it lets the renderer
and command ship while the v2 data mapping is finished as a localized change.

## Roadmap

- Wire the live dashboard data source to the v2 API.
- Migrate the remaining v1-based commands (`status`, `overview`, `build`,
  `cancel`) onto the v2 pipeline/workflow/job model.
- Broaden VCS support beyond GitHub for the classic commands.
- CI matrix across multiple Ruby versions (see [CI dogfood](ci-dogfood.md)).

> Roadmap items are plans, not promises — they describe direction, not shipped
> behavior.
