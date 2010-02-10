require 'rake'

desc "Submit package to Yast:Web osc repository (override project via OBS_PROJECT=)"
task :'osc_submit'  do
  require File.join(File.dirname(__FILE__), "osc_prepare")
  
  obs_project, package_name = osc_prepare
  
  puts "checking out package #{package_name} from project #{obs_project}"
  
  begin
    system("osc checkout '#{obs_project}' #{package_name}")
    
    #clean www dir and also clean before copy old entries in osc dir to test if package build after remove some file
    system("rm -vrf '#{obs_project}/#{package_name}/'*")  
    system("cp -v package/* '#{obs_project}/#{package_name}'")
    
    Dir.chdir File.join(Dir.pwd, obs_project, package_name) do
      puts "submitting package..."
      # long running, `foo` would only show output at the end
      system "osc addremove"
#      system "osc commit -m 'new version'"
      if $?.exitstatus != 0
        raise "Failed to submit"
      end
      puts "New package submitted to #{obs_project}"
    end
  ensure
    puts "cleaning"
    `rm -rf '#{obs_project}'`
  end
end
