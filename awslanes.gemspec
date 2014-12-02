# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lanes/version'

Gem::Specification.new do |spec|
  spec.name          = "awslanes"
  spec.version       = AwsLanes::VERSION
  spec.authors       = ["Dave Welch"]
  spec.email         = ["david@davidwelch.co"]
  spec.summary       = %q{Manage "lanes" of AWS machines}
  spec.description   = %q{Manage "lanes" of AWS machines, according to [principle here]}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = 'lanes' #spec.files.grep(%r{^bin/}) { |f| puts "Adding executable #{f}";File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency "thor"
  spec.add_dependency "awscli"
  spec.add_dependency "rest_client"
end
