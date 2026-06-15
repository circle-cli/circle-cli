# Credential safety + project discovery — result

Branch: `local/modernization-credentials` (local-only; no pushes/PRs/remotes touched).

## What changed

### Token precedence (`lib/circle/cli/repo.rb`)
- `circle_token` now resolves in order: `CIRCLE_TOKEN` → `CIRCLE_CLI_TOKEN` →
  git config `circleci.token`. Previously git config beat `CIRCLE_CLI_TOKEN`
  and `CIRCLE_TOKEN` was ignored.
- Storage is unchanged: `circle_token=` still writes git config (compat).
- New `circle_token_source` returns a human-readable provenance string
  (e.g. "git config (circleci.token)") and never contains the value.

### `circle token` (`lib/circle/cli/app.rb`)
- No-arg now reports *whether* a token is configured and *where it came from* —
  it no longer prints the value. (Previously it echoed the raw token.)
- `circle token --show` is the only path that prints the value; gated by a
  flag and proven by tests.
- `circle token <value>` saves and confirms without echoing the value.

### `circle login`
- No longer echoes the token after saving (was: "Your token has been set to
  '<value>'"). Reads with `echo: false`, validates against `/me`, and prints
  the user identity. Validation failure is a soft warning (token already saved),
  still without leaking the value.

### Discovery: `circle projects`
- Prints the resolved project slug for the current repo plus the caller's
  `/me/collaborations` (name, vcs-type, slug). `--json` for machine output.
- Read-only; no mutating API calls. Singular `circle project` was intentionally
  not added to avoid colliding with the internal private `project` helper.

### Docs (`README.md`)
- Documented token precedence, `circle token` status vs `--show`, `circle login`,
  and `circle projects`.

## Tests (`spec/circle/cli/{repo,app}_spec.rb`)
- All API mocked via WebMock; no real network.
- Repo specs clear `CIRCLE_TOKEN`/`CIRCLE_CLI_TOKEN` around each example and
  cover precedence + source attribution.
- App specs assert: `token` no-arg hides the value, `--show` reveals it,
  `login` validates via `/me` and never echoes the token, `projects` lists
  collaborations + slug (human and JSON).

## Verification
- `bundle exec rake spec` → **110 examples, 0 failures** (92.57% line coverage).
- `bundle exec ruby -Ilib bin/circle help` → all commands listed.
- Live `circle token` against this repo printed only
  "A CircleCI token is configured (source: git config (circleci.token))" —
  no secret value. No tokens or git config dumped at any point.
