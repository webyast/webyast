require 'rake'



desc "Submit package to Yast:Web osc repository"
task :'osc_submit'  do
  raise "No package/ directory found" if not File.exist?('package') and File.directory?('package')
  package_name = ""
  Dir.glob("package/*.spec").each do |file|
    package_name = file.gsub( /package\/(.*).spec/, '\1')
  end
  puts "package is #{package_name}"
  raise "cannot determine package name" if package_name.empty?  
  puts "checking out osc package from build"
  top_dir = Dir.pwd
  begin
    `osc checkout 'YaST:Web' #{package_name}`
    #clean www dir and also clean before copy old entries in osc dir to test if package build after remove some file
    `rm -rf 'YaST:Web/#{package_name}/*'`  
    `cp package/* 'YaST:Web/#{package_name}'`
    Dir.chdir File.join(Dir.pwd, "YaST:Web", package_name)
    puts "submiting package"
    # long running, `foo` would only show output at the end
    system "osc addremove"
    system "osc commit -m 'new version'"
    if $?.exitstatus != 0
      raise "Failed to submit"
    end
    puts "package built"
  ensure
    puts "cleaning"
    Dir.chdir top_dir
    `rm -rf 'YaST:Web'`
  end
end


