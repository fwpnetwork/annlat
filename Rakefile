require "bundler/gem_tasks"
require 'rake/testtask'

task :doc do
  `rdoc lib/`
end

Rake::TestTask.new do |t|
  t.libs << 'lib/annlat'
  t.libs << 'test'
  t.pattern = 'test/*_test.rb'
  t.verbose = true
end