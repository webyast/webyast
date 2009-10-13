
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
Rake::PackageTask.new('www', :noversion) do |p|
  p.need_tar_bz2 = true
  p.package_dir = 'package'

  # do not call git and do not remove old files if package task won't be executed
  # FIXME: this does not support calling the package task from another task!
  packaging = ARGV.include?('package') || ARGV.include?('package-local')

  if packaging
    #removing old stuff
    www_dir = File.join(Dir.pwd,"package", "www")
    FileUtils.rm_rf(www_dir) if File.directory?(www_dir)

    # package only the files which are available in the GIT repository
    filelist = `git ls-files . --exclude=.gitignore`.split("\n")

    if $?.exitstatus.zero?
	p.package_files.include filelist

	ignored = `git ls-files -o .`.split("\n")

	if $?.exitstatus.zero? and ignored.size > 0
	    $stderr.puts 'WARNING: Ignored files:'
	    $stderr.puts ignored
	end
    else
	$stderr.puts 'WARNING: Cannot get GIT listing, packaging all files' if packaging
	p.package_files.include('./**/*')
    end
  else
    p.package_files.include('./**/*')
  end

  #don't add IDE files
  p.package_files.exclude('./nbproject')
  #don't add generated documentation. If you want have it in package, generate it fresh
  p.package_files.exclude('./doc/app')
  # ignore backups
  p.package_files.exclude('./**/*.orig')
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
