require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

require 'rubygems/package_task'
spec = Gem::Specification.load(File.expand_path('../byteboozer2.gemspec', __FILE__))
Gem::PackageTask.new(spec).define

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task default: [:rubocop, :test]
