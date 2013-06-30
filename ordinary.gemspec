# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ordinary/version'

Gem::Specification.new do |spec|
  spec.name          = 'ordinary'
  spec.version       = Ordinary::VERSION
  spec.authors       = ['Takahiro Kondo']
  spec.email         = ['heartery@gmail.com']
  spec.description   = %q{It normalizes nondistructively specified attributes of any model}
  spec.summary       = %q{Normalizer for any model}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'activemodel'
end
