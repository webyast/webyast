
require 'rake'
require 'fileutils'

# name of the package (base file name)
PACKAGE_NAME = 'www'
# target directory for the package file
PACKAGE_DIR = 'package'

def remove_package_dir
  # remove the old package directory
  www_dir = File.join(Dir.pwd, PACKAGE_DIR, PACKAGE_NAME)
  FileUtils.rm_rf(www_dir) if File.directory?(www_dir)
end

def remove_old_package
  # remove the old tarball
  tarball = File.join(Dir.pwd, PACKAGE_DIR, "#{PACKAGE_NAME}.tar.bz2")
  FileUtils.rm_rf(tarball) if File.exists?(tarball)
end

def package_clean
  remove_package_dir
  remove_old_package
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
def create_package_task
  require 'rake/packagetask'

  Rake::PackageTask.new(PACKAGE_NAME, :noversion) do |p|
    p.need_tar_bz2 = true
    p.package_dir = PACKAGE_DIR

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
end

# this is just a dummy package task which creates the real Rake::PackageTask
# when it is invoked - this avoids removing of the old package and
# calling 'git ls-files' for every rake call (even 'rake -T')
desc "Build distribution package (no check, for testing only)"
task :"package-local" do
  # start from scratch, ensure that the package is fresh
  package_clean

  # create the real package task
  create_package_task

  # execute the real package task
  Rake::Task[:"#{PACKAGE_DIR}/#{PACKAGE_NAME}.tar.bz2"].invoke

  # remove the package dir, not needed anymore
  remove_package_dir
end

# define the same tasks as in Rake::PackageTask
desc "Remove package products"
task :clobber_package do
  remove_old_package
end

task :clobber => :clobber_package

desc "Force a rebuild of the package files"
# Note: 'repackage' can be simply redirected to 'package', the old package
# is always removed before creating a new package
task :repackage => :package

# vim: ft=ruby
