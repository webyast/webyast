# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "polkit1/version"

Gem::Specification.new do |s|
  s.name        = "polkit1"
  s.version     = PolKit1::VERSION
  s.authors     = ["Stefan Schubert"]
  s.email       = ["schubi@suse.de"]
  s.homepage    = ""
  s.summary     = %q{polkit bindings for ruby}
  s.description = %q{This extension provides polkit integration. The library provides a stable API for applications to use the authorization policies from polkit.}

  s.files         = `git ls-files`.split("\n").delete_if{|f| f.match(/\.gitignore$/)} + ['lib/polkit1.so']
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.extensions  << 'ext/polkit1/extconf.rb'

  # specify any dependencies here; for example:
  s.add_development_dependency 'rake-compiler', '> 0.4.1'
  s.add_development_dependency 'yard'

  s.add_runtime_dependency 'inifile'
end


