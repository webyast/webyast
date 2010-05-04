require 'rake'


desc "Submit package to Yast:Web osc repository (override project via OBS_PROJECT=)"
task :'osc_submit'  do
  require File.join(File.dirname(__FILE__), "osc_prepare")
  
  obs_project, package_name = osc_prepare
  
  puts "checking out package #{package_name} from project #{obs_project}"
  
  include FileUtils::Verbose
  begin
    sh "osc", "checkout", obs_project, package_name
    
    # clean www dir, and also clean old entries in osc dir to test if package builds after removing some file
    rm_rf Dir.glob("#{obs_project}/#{package_name}/*")
    cp Dir.glob("package/*"), "#{obs_project}/#{package_name}"
    
    Dir.chdir File.join(Dir.pwd, obs_project, package_name) do
      puts "submitting package..."
      sh "osc addremove"
      changes = `osc diff *.changes | sed -n '/^+---/,+2b;/^+++/b;s/^+//;T;p'`
      sh "osc", "commit", "-m", changes
      puts "New package submitted to #{obs_project}"
    end
  ensure
    puts "cleaning"
    rm_rf obs_project
  end
end
