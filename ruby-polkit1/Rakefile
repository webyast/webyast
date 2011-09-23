$: << File.join(File.dirname(__FILE__), "test")
require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'

task :default => [:compile, :docs, :test]

Hoe.plugin :yard

HOE = Hoe.spec 'polkit1' do
  developer('Stefan Schubert', 'schubi@suse.de')
  self.summary = "polkit bindings for ruby"
  self.description = "This extension provides polkit integration. The library provides a stable API for applications to use the authorization policies from polkit."
  self.readme_file = ['README', ENV['HLANG'], 'rdoc'].compact.join('.')
  self.history_file = ['CHANGELOG', ENV['HLANG'], 'rdoc'].compact.join('.')
  self.extra_rdoc_files = FileList['*.rdoc'] 
  self.extra_rdoc_files << "COPYING"
  self.clean_globs = [
    'lib/polkit1/*.{o,so,bundle,a,log,dll}',
  ]
 
  %w{ rake-compiler }.each do |dep|
    self.extra_dev_deps << [dep, '>= 0']
  end
  self.extra_dev_deps << ['yard', '>= 0']
  self.spec_extras = { :extensions => ["ext/polkit1/extconf.rb"] }
end


gem 'rake-compiler', '>= 0.4.1'
require 'rake/extensiontask'
Rake::ExtensionTask.new('polkit1')

task :package do
  FileUtils.cp Dir.glob("pkg/*.gem")[0].to_s, "package/"
end
