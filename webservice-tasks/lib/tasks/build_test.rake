require 'rake'



desc "Test builded package if it can build locally"
task :'build_test'  do
  raise "No package/ directory found" if not File.exist?('package') and File.directory?('package')
  package_name = ""
  Dir.glob("package/*.spec").each do |file|
    package_name = file.gsub( /package\/(.*).spec/, '\1')
  end
  puts "package is #{package_name}"
  raise "cannot determine package name" if package_name.empty?  
  puts "checking out osc package to build"
  `osc checkout 'YaST:Web' #{package_name}`
  `rm -rf package/www`  
  `cp package/* 'YaST:Web/#{package_name}'`
  Dir.chdir File.join(Dir.pwd, "YaST:Web", package_name)
  puts "start building package"
  puts `osc build`
  if $?.exitstatus != 0
    raise "Failed to build"
  end
  puts "package builded, cleaning"
  Dir.chdir File.join(Dir.pwd, '..', '..')
  `rm -rf 'YaST:WeB'`
end


