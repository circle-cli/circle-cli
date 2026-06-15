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

  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata = {
    'source_code_uri' => spec.homepage,
    'bug_tracker_uri' => "#{spec.homepage}/issues"
  }

  spec.files         = `git ls-files`.split
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
