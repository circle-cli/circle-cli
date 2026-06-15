# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-06-14

### Added
- CircleCI API v2 client foundation (`Circle::CLI::ApiClient`).
- `circle me`, `circle projects`, `circle pipelines`, `circle workflows`, and
  `circle jobs` commands (API v2).
- Modern terminal pipeline dashboard (`circle dashboard`, with `--sample`).
- CircleCI dogfood pipeline (`.circleci/config.yml`).
- GitHub Pages documentation site under `docs/`.

### Changed
- Require Ruby 3.3.
- `circle status`, `circle overview`, and `circle open` now use the CircleCI API
  v2 read-only pipeline/workflow/job model.
- `circle token` now reports configured status/source by default instead of
  printing the token value; use `circle token --show` to reveal it explicitly.
- `circle login` validates saved tokens with `/me` without echoing the token.
- Modernized gem packaging metadata: `documentation_uri`, `changelog_uri`,
  `allowed_push_host`, and `rubygems_mfa_required`.
- Slimmed the published gem to runtime files only — specs, cassettes, the docs
  site, CI config, and dev dotfiles are no longer shipped in the package.

### Fixed
- Corrected "Circle CI" to "CircleCI" in the gem summary/description, README,
  and the `build`/`login` command help text.

## [0.1.3]

- Last release on the legacy line. See git history for details.
