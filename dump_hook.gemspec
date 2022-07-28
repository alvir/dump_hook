# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dump_hook/version'

Gem::Specification.new do |spec|
  spec.name          = "dump_hook"
  spec.version       = DumpHook::VERSION
  spec.authors       = ["Alexander Ryazantsev"]
  spec.email         = ["shurik.v.r@gmail.com"]

  spec.summary       = %q{Dumps to cache you backgrounds}
  spec.description   = %q{We use it for our capybara/Cucumber features.}
  spec.homepage    = "https://github.com/Anadea/dump_hook"
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
