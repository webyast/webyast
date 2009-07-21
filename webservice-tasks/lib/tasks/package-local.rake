
require 'rake'
require 'rake/packagetask'

require "#{File.dirname(__FILE__)}/rake_rename_task"

package_backup = '*__package_task_backup__*'

# backup the current existing :package task
if Rake::Task.task_defined?(:package)
    puts "saving backup"
    Rake::Task[:package].rename(package_backup)
end

# create new package task
Rake::PackageTask.new('www', :noversion) do |p|
  p.need_tar_bz2 = true
  p.package_dir = 'package'
  p.package_files.include('**/*')
  p.package_files.exclude('package')
  p.package_files.exclude('coverage')
end

# rename 'package' task to 'package-local' task
Rake::Task[:package].rename(:"package-local")

# restore the original :package task
if Rake::Task.task_defined?(package_backup)
    puts "restoring backup"
    Rake::Task[package_backup].rename(:package)
end

# vim: ft=ruby
