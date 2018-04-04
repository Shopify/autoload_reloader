require "bundler/gem_tasks"
require "rake/testtask"

rails_test_files = ["test/active_support_ext_test.rb"]

namespace :test do
  Rake::TestTask.new(:base) do |t|
    t.libs << "test"
    t.test_files = FileList["test/**/*_test.rb"] - rails_test_files
  end

  Rake::TestTask.new(:rails) do |t|
    t.libs << "test"
    t.test_files = rails_test_files
  end
end

task test: ['test:base', 'test:rails']

task :default => :test
