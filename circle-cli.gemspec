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
  spec.homepage      = 'https://github.com/circle-cli/circle-cli'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'circleci', '~> 1.0.3', '>= 1.0.3'
  spec.add_dependency 'git', '~> 1.3.0', '>= 1.3.0'
  spec.add_dependency 'gitable', '~> 0.3.1', '>=0.3.1'
  spec.add_dependency 'launchy', '~> 2.4.3', '>= 2.4.3'
  spec.add_dependency 'thor', '~> 0.19.1', '>= 0.19.1'

  spec.add_development_dependency 'bundler', '~> 1.5', '>= 1.5'
  spec.add_development_dependency 'rake', '~> 11.2.2', '>= 11.2.2'
  spec.add_development_dependency 'rspec', '~> 3.5.0', '>= 3.5.0'
  spec.add_development_dependency 'vcr', '~> 3.0.3', '>= 3.0.3'
  spec.add_development_dependency 'webmock', '~> 2.1.0', '>= 2.1.0'
  spec.add_development_dependency 'simplecov', '~> 0.12.0', '>= 0.12.0'
end
