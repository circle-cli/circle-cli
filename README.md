# Circle CLI
Command line tools for Circle CI

[![Gem Version](https://badge.fury.io/rb/circle-cli.svg)](https://badge.fury.io/rb/circle-cli)

![circle-cli demo](https://cloud.githubusercontent.com/assets/306238/13765850/b410ea98-ea22-11e5-8cb9-4942d6071654.gif)

## Installation

    $ gem install circle-cli

## Setup

1. Install Circle-CLI

  ```
  $ gem install circle-cli
  ```

2. Add your CircleCI token

  ```
  $ circle login          # guided: opens CircleCI, saves the token, validates it
  # or, non-interactively:
  $ circle token <your token>
  ```

  The token is read from the first of these that is set, in order:

  1. `CIRCLE_TOKEN` environment variable
  2. `CIRCLE_CLI_TOKEN` environment variable
  3. `circleci.token` in git config (where `circle token <value>` and
     `circle login` save it)

## Usage

> The read-only commands `circle status`, `circle overview`, and `circle open`
> now read from the CircleCI API v2 and require a configured token (see Setup).

- Check whether a token is configured (the value is never printed)

  ```
  $ circle token          # reports status and source, not the secret
  $ circle token --show   # prints the token value (use with care)
  ```

- Discover the current project slug and the projects your token can access

  ```
  $ circle projects          # human-readable table
  $ circle projects --json   # machine-readable
  ```

- Get the CI status for the HEAD of your current branch

  ```
  $ circle
  ```

- Start a new CI build for the HEAD of your current branch

  ```
  $ circle build
  ```

- Watch the most recent CI build for your current branch

  ```
  $ circle --watch
  ```

- Cancel the most recent CI build for your current branch

  ```
  $ circle cancel
  ```

- Open the results page for the latest CI run

  ```
  $ circle open
  ```

- Preview the modern pipeline dashboard (no token needed)

  ```
  $ circle dashboard --sample
  ```

- For additional help

  ```
  $ circle help
  ```

## Documentation

Full documentation lives in the [`docs/`](docs/) folder and is published with
GitHub Pages (Pages → Deploy from a branch → `/docs`):

- [Quickstart](docs/quickstart.md)
- [Commands](docs/commands.md)
- [Configuration](docs/configuration.md)
- [CI dogfood](docs/ci-dogfood.md)
- [Migration & roadmap](docs/migration.md)
- [Contributing](docs/contributing.md)

## Development

This project targets Ruby 3.3 (see `.ruby-version`). The steps below use the
Homebrew `ruby@3.3` formula and install gems into a project-local path so you
don't touch the system gem directory.

1. Install Ruby 3.3 via Homebrew (if you haven't already):

  ```
  $ brew install ruby@3.3
  ```

2. Put the Homebrew Ruby on your `PATH` for the current shell:

  ```
  $ export PATH="/opt/homebrew/opt/ruby@3.3/bin:$PATH"
  $ ruby --version   # => ruby 3.3.x
  ```

3. Install dependencies into a project-local `vendor/bundle` (this writes
   `.bundle/config`, which is git-ignored, so no machine-specific paths are
   committed):

  ```
  $ bundle config set --local path 'vendor/bundle'
  $ bundle install
  ```

4. Run the specs:

  ```
  $ bundle exec rake spec
  ```

5. Run the CLI from the source tree without installing the gem:

  ```
  $ bundle exec ruby -Ilib bin/circle help
  ```

6. Build the gem:

  ```
  $ gem build circle-cli.gemspec
  ```

## Contributing

1. Fork it ( http://github.com/circle-cli/circle-cli/fork )
2. Create your feature branch with your initials (`git checkout -b dsk/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
