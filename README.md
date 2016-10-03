# Circle CLI
Command line tools for Circle CI

[![Gem Version](https://badge.fury.io/rb/circle-cli.svg)](https://badge.fury.io/rb/circle-cli)
[![CircleCI Status](https://circleci.com/gh/circle-cli/circle-cli.svg?style=shield&circle-token=e24d4c43a7437111a6ee5915901017a8419ddbf4)](https://circleci.com/gh/circle-cli/circle-cli)
[![Dependency Status](https://gemnasium.com/circle-cli/circle-cli.svg)](https://gemnasium.com/circle-cli/circle-cli)
[![Code Climate](https://codeclimate.com/github/circle-cli/circle-cli/badges/gpa.svg)](https://codeclimate.com/github/circle-cli/circle-cli)
[![Test Coverage](https://codeclimate.com/github/circle-cli/circle-cli/badges/coverage.svg)](https://codeclimate.com/github/circle-cli/circle-cli/coverage)

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
  $ circle token <your token>
  ```

## Usage

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

- For additional help

  ```
  $ circle help
  ```

## Contributing

1. Fork it ( http://github.com/circle-cli/circle-cli/fork )
2. Create your feature branch with your initials (`git checkout -b dsk/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
