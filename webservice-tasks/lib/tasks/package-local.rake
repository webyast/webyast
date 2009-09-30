
require 'rake'
require 'rake/packagetask'
require 'fileutils'

require "#{File.dirname(__FILE__)}/rake_rename_task"

package_backup = '*__package_task_backup__*'

# backup the current existing :package task
if Rake::Task.task_defined?(:package)
    Rake::Task[:package].rename(package_backup)
end

# create new package task

#removing old stuff
www_dir = File.join(Dir.pwd,"package", "www")
FileUtils.rm_rf(www_dir) if File.directory?(www_dir)

Rake::PackageTask.new('www', :noversion) do |p|
  p.need_tar_bz2 = true
  p.package_dir = 'package'
  p.package_files.include('./**/*')
  p.package_files.exclude('./package')
  p.package_files.exclude('./coverage')
  p.package_files.exclude('./test')
  p.package_files.exclude('./db/*.sqlite3')
  p.package_files.exclude('./db/schema.rb')
  p.package_files.exclude('./log/*.log')
  p.package_files.exclude('./vendor/plugins/rails_rcov')
  p.package_files.exclude('./public/vendor/text/locale')
  p.package_files.exclude('./public/vendor/text/po')
  p.package_files.exclude('./public/vendor/images')
  p.package_files.exclude('./public/vendor/stylesheets')
end

# rename 'package' task to 'package-local' task
Rake::Task[:package].rename(:"package-local")

# restore the original :package task
if Rake::Task.task_defined?(package_backup)
    Rake::Task[package_backup].rename(:package)
end

# vim: ft=ruby
