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
  top_dir = Dir.pwd
  begin
    `osc checkout 'YaST:Web' #{package_name}`
    #clean www dir and also clean before copy old entries in osc dir to test if package build after remove some file
    `rm -rf package/www 'YaST:Web/#{package_name}/*'`  
    `cp package/* 'YaST:Web/#{package_name}'`
    Dir.chdir File.join(Dir.pwd, "YaST:Web", package_name)
    puts "start building package. output will appear at the end."
    puts `osc build`
    if $?.exitstatus != 0
      raise "Failed to build"
    end
    puts "package built"
  ensure
    puts "cleaning"
    Dir.chdir top_dir
    `rm -rf 'YaST:Web'`
  end
end


