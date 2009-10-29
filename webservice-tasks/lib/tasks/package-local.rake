
require 'rake'
require 'rake/packagetask'
require 'fileutils'

require "#{File.dirname(__FILE__)}/rake_rename_task"

# temporary name for the package task backup
PACKAGE_BACKUP = '*__package_task_backup__*'
# name of the package (base file name)
PACKAGE_NAME = 'www'
# target directory for the package file
PACKAGE_DIR = 'package'

# backup the current existing :package task
if Rake::Task.task_defined?(:package)
    Rake::Task[:package].rename(PACKAGE_BACKUP)
end

def remove_old_package
  #removing old stuff
  www_dir = File.join(Dir.pwd, PACKAGE_DIR, PACKAGE_NAME)
  FileUtils.rm_rf(www_dir) if File.directory?(www_dir)
end

# add all GIT files under the current directory to the package_task
def add_git_files(package_task)
  # package only the files which are available in the GIT repository
  filelist = `git ls-files . --exclude=.gitignore`.split("\n")

  if $?.exitstatus.zero?
      # add ./ prefix so the exclude patterns match
      filelist.map! { |f| "./#{f}"}

      package_task.package_files.include filelist

      ignored = `git ls-files -o .`.split("\n")

      if $?.exitstatus.zero? and ignored.size > 0
	  ignored.each {|f| $stderr.puts "WARNING: Ignoring file: #{f}"}
      end
  else
      $stderr.puts 'WARNING: Cannot get GIT listing, packaging all files'
      package_task.package_files.include('./**/*')
  end
end

# create new package task
Rake::PackageTask.new(PACKAGE_NAME, :noversion) do |p|
  p.need_tar_bz2 = true
  p.package_dir = PACKAGE_DIR

  remove_old_package

  add_git_files p

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
if Rake::Task.task_defined?(PACKAGE_BACKUP)
    Rake::Task[PACKAGE_BACKUP].rename(:package)
end

# vim: ft=ruby
