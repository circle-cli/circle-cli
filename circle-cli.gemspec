# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'circle/cli/version'

Gem::Specification.new do |spec|
  spec.name          = 'circle-cli'
  spec.version       = Circle::CLI::VERSION
  spec.authors       = ['Derek Keith', 'Jean Boussier']
  spec.email         = ['derek@codeurge.com', 'jean.boussier@gmail.com']
  spec.summary       = %q{Command line tools for Circle CI}
  spec.description   = %q{A bunch of commands useful to deal with Circle CI without leaving your terminal.}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'circleci'
  spec.add_dependency 'git'
  spec.add_dependency 'gitable'
  spec.add_dependency 'launchy'
  spec.add_dependency 'thor'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'simplecov'
end
