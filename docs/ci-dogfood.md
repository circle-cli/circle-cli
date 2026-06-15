---
title: CI Dogfood
---

# CI dogfood

Circle CLI builds and tests itself on CircleCI. The pipeline config lives at
[`.circleci/config.yml`](https://github.com/circle-cli/circle-cli/blob/master/.circleci/config.yml).

## What the pipeline does

A single `test` job runs on Ruby 3.3 (`cimg/ruby:3.3`) and:

1. **Installs dependencies** with Bundler, into a project-local `vendor/bundle`,
   cached between runs.
2. **Runs the specs** with `bundle exec rake spec`.
3. **Builds the gem** with `gem build circle-cli.gemspec` to catch packaging
   regressions.
4. **Smoke-tests the CLI** straight from the source tree:
   - `bundle exec ruby -Ilib bin/circle help`
   - `bundle exec ruby -Ilib bin/circle dashboard --sample --no-color --width 80`

## No token required

Every step is unauthenticated. The smoke commands (`help` and the `--sample`
dashboard) deliberately avoid any command that needs a CircleCI token or network
access, so the pipeline runs with **no secrets, contexts, or environment
variables**. There is nothing to leak.

## Caching

Bundled gems are cached with a key derived from `circle-cli.gemspec`:

```
v1-bundle-{{ checksum "circle-cli.gemspec" }}
```

`Gemfile.lock` is git-ignored in this project, so the gemspec is the most stable
available cache key. Bump the `v1-` prefix to invalidate the cache wholesale.

## Roadmap

- Matrix across multiple Ruby versions once 3.3 is green.
- A separate, opt-in job for authenticated end-to-end checks, gated behind a
  context so the default pipeline stays secret-free.
