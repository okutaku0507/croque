# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "croque/version"

Gem::Specification.new do |spec|
  spec.name          = "croque"
  spec.version       = Croque::VERSION
  spec.authors       = ["Takuya Okuhara"]
  spec.email         = ["okutaku0507@gmail.com"]
  spec.summary       = "Croque is a aggregator of log."
  spec.description   = "Croque is a aggregator of log."
  spec.homepage      = "https://github.com/okutaku0507/croque"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 4"

  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
