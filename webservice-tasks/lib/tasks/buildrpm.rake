require 'rake'

desc "Build rpms with rpmbuild, no source check"
task :'buildrpm-local' => :'package-local' do
 Dir.chdir 'package' do
  specs = Dir.glob('*.spec')
  raise "No spec file found" if specs.empty?  
  spec = specs.first
  sh "rpmbuild", "-bb", spec
 end
end

desc "Build rpm with rpmbuild"
task :buildrpm => [ :check_syntax, :git_check, :'buildrpm-local']


