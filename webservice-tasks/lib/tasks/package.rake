require 'rake'
require 'rake/packagetask'

Rake::PackageTask.new('www', :noversion) do |p|
  p.need_tar_bz2 = true
  p.package_dir = 'package'
  p.package_files.include('**/*')
  p.package_files.exclude('package')
end


