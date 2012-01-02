# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "webyast-system"
  s.version = "0.1"
  s.authors = ["WebYaST team"]
  s.email = %q{webyast-devel@opensuse.org}
  s.summary     =  s.name
  s.description = "Gem #{s.name}"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
