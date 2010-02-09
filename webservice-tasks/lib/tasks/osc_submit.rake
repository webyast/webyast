require 'rake'

desc "Submit package to Yast:Web osc repository (override project via OBS_PROJECT=)"
task :'osc_submit'  do
  raise "No package/ directory found" if not File.exist?('package') and File.directory?('package')
  obs_project = ENV["OBS_PROJECT"] || "YaST:Web"
  package_name = ""
  Dir.glob("package/*.spec").each do |file|
    package_name = file.gsub( /package\/(.*).spec/, '\1')
  end
  puts "package is #{package_name}"
  raise "cannot determine package name" if package_name.empty?  
  puts "checking out package #{package_name} from project #{obs_project}"
  top_dir = Dir.pwd
  begin
    system("osc checkout '#{obs_project}' #{package_name}")
    #clean www dir and also clean before copy old entries in osc dir to test if package build after remove some file
    system("rm -vrf '#{obs_project}/#{package_name}/'*")  
    system("cp -v package/* '#{obs_project}/#{package_name}'")
    Dir.chdir File.join(Dir.pwd, obs_project, package_name)
    puts "submitting package..."
    # long running, `foo` would only show output at the end
    system "osc addremove"
    system "osc commit -m 'new version'"
    if $?.exitstatus != 0
      raise "Failed to submit"
    end
    puts "New package submitted to #{obs_project}"
  ensure
    puts "cleaning"
    Dir.chdir top_dir
    `rm -rf '#{obs_project}'`
  end
end
