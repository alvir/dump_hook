# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dump_hook/version'

Gem::Specification.new do |spec|
  spec.name          = "dump_hook"
  spec.version       = DumpHook::VERSION
  spec.authors       = ["Alexander Ryazantsev"]
  spec.email         = ["shurik.v.r@gmail.com"]

  spec.summary       = "Speed up acceptance and system tests by caching and restoring database state"
  spec.description   = "DumpHook speeds up your Rails system and acceptance tests by dumping and restoring " \
                       "database state instead of recreating it from scratch on every run. " \
                       "Supports PostgreSQL and MySQL. Works with Capybara, RSpec, Cucumber, and Minitest."
  spec.homepage    = "https://github.com/alvir/dump_hook"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'timecop'

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "sequel"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "mysql2"
end
