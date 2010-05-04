require 'rake'

desc "Build package locally"
task :'osc_build'  do
  require File.join(File.dirname(__FILE__), "osc_prepare")
  
  build_dist = ENV["DIST"] || "openSUSE_11.2"

  obs_project, package_name = osc_prepare
  
  puts "Building package #{package_name} from project #{obs_project}"

  require 'fileutils'
  require 'tmpdir'
  
  pkg_dir = File.join(Dir.tmpdir, obs_project, build_dist)
  FileUtils.makedirs pkg_dir
  
  begin
    system("osc checkout '#{obs_project}' #{package_name} > /dev/null")
    
    #clean www dir and also clean before copy old entries in osc dir to test if package build after remove some file
    system("rm -vrf '#{obs_project}/#{package_name}/'*")  
    system("cp -v package/* '#{obs_project}/#{package_name}'")

    Dir.chdir File.join(Dir.pwd, obs_project, package_name) do
      puts "building package..."

      sh "osc build --no-verify --release=1 --root=/var/tmp/build-root-#{build_dist} --keep-pkgs=#{pkg_dir} --prefer-pkgs=#{pkg_dir} #{build_dist} > /dev/null"
    end
  ensure
    puts "cleaning"
    `rm -rf '#{obs_project}'`
  end
end
