# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'annlat/version'

Gem::Specification.new do |spec|
  spec.name          = "annlat"
  spec.version       = Annlat::VERSION
  spec.authors       = ["Alexander Shevtsov"]
  spec.email         = ["randomlogin76@gmail.com"]
  spec.summary       = "Learnleague gem with libraries"
  spec.description   = ''
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"

end
