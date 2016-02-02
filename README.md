# Circle CLI

Command line tools for Circle CI

## Installation

    $ gem install circle-cli

## Setup

1. Install Circle-CLI

  ```
  $ gem install circle-cli
  ```

2. Add your GitHub token

  ```
  $ circle github-token <github-token>
  ```

3. Add your CircleCI token

  ```
  $ circle token <circle-ci-token>
  ```
  
## Usage

- Get the CI status for the HEAD of your current branch

  ```
  $ circle
  ```
  
- Open the results page for the latest CI run

  ```
  $ circle open
  ```

## Contributing

1. Fork it ( http://github.com/codeurge/circle-cli/fork )
2. Create your feature branch with your initials (`git checkout -b dsk/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
