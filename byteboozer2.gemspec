# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'byteboozer2/version'

Gem::Specification.new do |spec|
  spec.name          = 'byteboozer2'
  spec.version       = ByteBoozer2::VERSION
  spec.authors       = ['Pawel Krol']
  spec.email         = ['djgruby@gmail.com']

  spec.summary       = 'A data cruncher for Commodore files written in pure Ruby'
  spec.description   = 'This is a native Ruby port of David Malmborg\'s ByteBoozer 2.0.'
  spec.homepage      = 'https://github.com/pawelkrol/byteboozer2_ruby'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.0.1'

  spec.add_development_dependency 'awesome_print', '~> 1.9.2'
  spec.add_development_dependency 'bundler',       '~> 2.2.16'
  spec.add_development_dependency 'json',          '~> 2.5.1'
  spec.add_development_dependency 'minitest',      '~> 5.14.4'
  spec.add_development_dependency 'rake',          '~> 13.0.3'
  spec.add_development_dependency 'rubocop',       '~> 1.13.0'

  spec.add_runtime_dependency 'activemodel', '~> 6.1.3.1'
end
