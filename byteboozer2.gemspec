lib = File.expand_path('../lib', __FILE__)
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

  spec.add_development_dependency 'awesome_print', '~> 1.8.0'
  spec.add_development_dependency 'bundler',       '~> 1.16.0'
  spec.add_development_dependency 'json',          '~> 2.1.0'
  spec.add_development_dependency 'minitest',      '~> 5.10.3'
  spec.add_development_dependency 'rake',          '~> 12.3.0'
  spec.add_development_dependency 'rubocop',       '~> 0.52.0'

  spec.add_runtime_dependency 'activemodel', '~> 5.1.4'
end
