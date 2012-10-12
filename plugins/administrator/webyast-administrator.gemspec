# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "webyast-administrator"
  s.version = "0.3.5"
  s.authors = ["WebYaST team"]
  s.summary = "Webyast module for configuring administrator settings"
  s.email = "yast-devel@opensuse.org"
  s.licenses = ['GPL-2.0']

  ignore_files = ["package/rubygem-webyast-administrator.changes", "package/rubygem-webyast-administrator.spec"]

  s.files         = `git ls-files`.split("\n").delete_if{|f| f.match(/^locale\/.*\.po$/) || f.match(/.gitignore$/) || ignore_files.include?(f)}.concat(Dir.glob("locale/**/*.mo")) rescue []
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n") rescue []
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) } rescue []
  s.require_paths = ["lib"]
end
