# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ej/version'

Gem::Specification.new do |spec|
  spec.name          = "ej"
  spec.version       = Ej::VERSION
  spec.authors       = ["toyama0919"]
  spec.email         = ["toyama0919@gmail.com"]
  spec.summary       = %q{Command-line Elasticsearch TO JSON processor.}
  spec.description   = %q{Command-line Elasticsearch TO JSON processor.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-doc"
  spec.add_runtime_dependency "thor"
  spec.add_runtime_dependency "yajl-ruby"
  spec.add_runtime_dependency "elasticsearch"
  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "hashie"
end