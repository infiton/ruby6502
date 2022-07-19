# frozen_string_literal: true

require File.expand_path("lib/ruby6502/version", __dir__)

Ruby6502::GEMSPEC = Gem::Specification.new do |s|
  s.name        = "ruby6502"
  s.version     = Ruby6502::VERSION
  s.summary     = "Ruby 6502 emulator"
  s.description = "A Ruby emulator for the 6502. The 6502 is powered by http://rubbermallet.org/fake6502.c"
  s.authors     = ["Kyle Tate"]
  s.email       = "kbt.tate@gmail.com"
  s.files       = Dir.glob("{lib}/**/*") + Dir.glob("{ext}/**/*")

  s.required_ruby_version = ">= 2.7"
  s.add_development_dependency("minitest", "~> 5.16")
  s.add_development_dependency("rake", "~> 13.0")
  s.add_development_dependency("rake-compiler", "~> 1.2")
  s.add_development_dependency("rubocop", "~> 1.31")
  s.add_development_dependency("rubocop-shopify", "~> 2.8")
  s.extensions = ["ext/ruby6502/extconf.rb"]
  s.homepage    = "http://github.com/infiton/ruby6502"
  s.license     = "MIT"
end
