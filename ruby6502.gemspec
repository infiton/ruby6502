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

  s.required_ruby_version = ">= 2.4"
  s.extensions = ["ext/ruby6502/extconf.rb"]
  s.homepage    = "http://github.com/infiton/ruby6502"
  s.license     = "MIT"
end
