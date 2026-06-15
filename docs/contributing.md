---
title: Contributing
---

# Contributing

## Local development

This project targets Ruby 3.3 (see `.ruby-version`). The steps below use the
Homebrew `ruby@3.3` formula and install gems into a project-local path so you
don't touch the system gem directory.

1. Install Ruby 3.3 (if you haven't already):

   ```
   $ brew install ruby@3.3
   ```

2. Put it on your `PATH` for the current shell:

   ```
   $ export PATH="/opt/homebrew/opt/ruby@3.3/bin:$PATH"
   $ ruby --version   # => ruby 3.3.x
   ```

3. Install dependencies into a project-local `vendor/bundle` (writes
   `.bundle/config`, which is git-ignored):

   ```
   $ bundle config set --local path vendor/bundle
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

## Tests

Specs live under `spec/` and use RSpec, with VCR/WebMock cassettes under
`spec/cassettes/` so the suite runs offline. Please add or update specs with
your change and keep the suite green.

## Pull requests

1. Fork the repository.
2. Create a feature branch with your initials (`git checkout -b dsk/my-feature`).
3. Commit your changes.
4. Push and open a pull request.

The [CI dogfood pipeline](ci-dogfood.md) runs specs, a gem build, and CLI smoke
tests on every push — make sure it's green before requesting review.
