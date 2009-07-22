require 'rake'



desc "Build rpms with rpmbuild, no source check"
task :'buildrpm-local' => :'package-local' do
  raise "No package/ directory found" if not File.exist?('package') and File.directory?('package')
  Dir.chdir 'package'
  specs = Dir.glob('*.spec')
  raise "No spec file found" if specs.empty?  
  spec = specs.first
  `rpmbuild -bb #{spec}`
  if $?.exitstatus != 0
    raise "Failed to build #{File.join(Dir.pwd, spec)}"
  end
  Dir.chdir File.join(Dir.pwd, '..')
end


desc "Build rpm with rpmbuild"
task :buildrpm => [ :check_syntax, :git_check, :'buildrpm-local']


