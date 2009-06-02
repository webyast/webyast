
require 'rake'
require 'rake/packagetask'

require "#{File.dirname(__FILE__)}/rake_rename_task"

# create new package task
Rake::PackageTask.new('www', :noversion) do |p|
  p.need_tar_bz2 = true
  p.package_dir = 'package'
  p.package_files.include('**/*')
  p.package_files.exclude('package')
end

# rename 'package' task to 'package-local' task
Rake::Task[:package].rename(:"package-local")

# vim: ft=ruby
