# Prepare to handle a package with 'osc'"

#
# obs_project, package_name = osc_prepare
#

def osc_prepare
  File.directory?('package') || raise("No package/ directory found")
  obs_project = ENV["OBS_PROJECT"] || "YaST:Web"
  package_name = ""
  Dir.glob("package/*.spec").each do |file|
    package_name = file.gsub( /package\/(.*).spec/, '\1')
  end
  puts "package is #{package_name}"
  raise "cannot determine package name" if package_name.empty?  
  [obs_project, package_name]
end
