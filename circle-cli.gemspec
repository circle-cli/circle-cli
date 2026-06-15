# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'circle/cli/version'

Gem::Specification.new do |spec|
  spec.name          = 'circle-cli'
  spec.version       = Circle::CLI::VERSION
  spec.authors       = ['Derek Keith', 'Jean Boussier']
  spec.email         = ['derek@codeurge.com', 'jean.boussier@gmail.com']
  spec.summary       = %q{Command line tools for CircleCI}
  spec.description   = %q{A bunch of commands useful to deal with CircleCI without leaving your terminal.}
  spec.homepage      = 'https://github.com/circle-cli/circle-cli'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata = {
    'source_code_uri'       => spec.homepage,
    'documentation_uri'     => "#{spec.homepage}/tree/master/docs",
    'changelog_uri'         => "#{spec.homepage}/blob/master/CHANGELOG.md",
    'bug_tracker_uri'       => "#{spec.homepage}/issues",
    'allowed_push_host'     => 'https://rubygems.org',
    'rubygems_mfa_required' => 'true'
  }

  # Ship only what the installed gem needs at runtime. Development and docs
  # assets (specs, cassettes, the docs site, CI config, dev dotfiles) live in
  # the repository and on GitHub Pages, so they are excluded here to keep the
  # published package lean.
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.start_with?('spec/', 'docs/', '.circleci/') ||
      %w[.gitignore .rspec .ruby-version Gemfile Rakefile].include?(f)
  end
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'circleci', '~> 1.0', '>= 1.0.3'
  spec.add_dependency 'git', '>= 1.3', '< 3.0'
  spec.add_dependency 'gitable', '>= 0.4', '< 1.0'
  spec.add_dependency 'launchy', '>= 2.4', '< 4.0'
  spec.add_dependency 'pastel', '>= 0.8', '< 1.0'
  spec.add_dependency 'thor', '>= 0.19', '< 2.0'

  spec.add_development_dependency 'rake', '>= 12.0'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'vcr', '>= 3.0', '< 7.0'
  spec.add_development_dependency 'webmock', '>= 2.3', '< 4.0'
  spec.add_development_dependency 'simplecov', '>= 0.12', '< 1.0'
end
