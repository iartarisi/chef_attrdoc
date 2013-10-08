# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chef_attrdoc/version'

Gem::Specification.new do |spec|
  spec.name          = "chef_attrdoc"
  spec.version       = ChefAttrdoc::VERSION
  spec.authors       = ["Ionuț Arțăriși"]
  spec.email         = ["iartarisi@suse.cz"]
  spec.description   = %q{Generate README.md docs from chef cookbook attributesf file}
  spec.summary       = %q{Generate README.md docs from chef cookbook attributesf file}
  spec.homepage      = "https://github.com/mapleoin/chef-attrdoc"
  spec.license       = "Apache"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
end
