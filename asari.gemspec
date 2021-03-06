# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "asari/version"

Gem::Specification.new do |s|
  s.name        = "asari"
  s.version     = Asari::VERSION
  s.authors     = ["Tommy Morgan"]
  s.email       = ["tommy@wellbredgrapefruit.com"]
  s.homepage    = "http://github.com/duwanis/asari"
  s.summary     = %q{Asari is a Ruby interface for AWS CloudSearch.}
  s.description = %q{Asari s a Ruby interface for AWS CloudSearch}

  s.rubyforge_project = "asari"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"

  s.add_runtime_dependency "httparty"

  s.add_development_dependency "rspec"
end
