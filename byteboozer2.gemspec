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

  spec.required_ruby_version = '>= 4.0.6'

  spec.add_dependency 'activemodel', '~> 8.1.3.1'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
