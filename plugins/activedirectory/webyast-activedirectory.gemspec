# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "webyast-activedirectory"
  s.version = "0.1"
  s.authors = ["WebYaST team"]
  s.summary     =  "Webyast module for configuring samba settings"
  s.email = "yast-devel@opensuse.org"
  s.licenses = ['GPL-2.0']

 s.files         = `git ls-files`.split("\n").delete_if{|f| f.match(/^locale\/.*\.po$/) || f.match(/.gitignore$/)}.concat(Dir.glob("locale/**/*.mo"))
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
