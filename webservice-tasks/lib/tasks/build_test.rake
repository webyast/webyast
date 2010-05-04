require 'rake'

desc "Test builded package if it can build locally"
task :'build_test'  do
  require File.join(File.dirname(__FILE__), "osc_prepare")
  obs_project, package_name = osc_prepare
  puts "checking out osc package from build"
  begin
    `osc checkout '#{obs_project}' #{package_name}`
    #clean www dir and also clean before copy old entries in osc dir to test if package build after remove some file
    `rm -rf package/www '#{obs_project}/#{package_name}/*'`  
    `cp package/* '#{obs_project}/#{package_name}'`
    Dir.chdir File.join(Dir.pwd, obs_project, package_name) do
      sh "osc build"
    end
    puts "package built"
  ensure
    puts "cleaning"
    `rm -rf '#{obs_project}'`
  end
end


