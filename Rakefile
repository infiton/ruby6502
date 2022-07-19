# frozen_string_literal: true

require "rake/testtask"
require "rake/extensiontask"

Rake::ExtensionTask.new("ruby6502") do |ext|
  ext.lib_dir = "lib/ruby6502"
end

Rake::TestTask.new(:test) do |test|
  test.pattern = "test/test_*.rb"
end

desc "Run tests"
task default: :test
