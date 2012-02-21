#--
# Webyast framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++


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
  filelist = `git ls-files . | grep -v \\.gitignore`.split("\n")

  if $?.exitstatus.zero?
    exclude_list = [ /^package\//, /^nbproject\//, /^coverage\//,
      /^vendor\/plugins\/rails_rcov\// ]

    exclude_list.each do |exclude|
      filelist.delete_if do |f|
        f.match exclude
      end
    end

    package_task.package_files.include filelist

    ignored = `git ls-files -o .`.split("\n")

    if $?.exitstatus.zero? and ignored.size > 0
      ignored.each {|f| $stderr.puts "WARNING: Ignoring file: #{f}"}
    end
  else
    raise 'ERROR: Cannot get GIT listing ("git ls-files" failed)'
  end
end

# create new package task
def create_package_task
  require 'rake/packagetask'

  Rake::PackageTask.new(PACKAGE_NAME, :noversion) do |p|
    p.need_tar_bz2 = true
    p.package_dir = PACKAGE_DIR

    add_git_files p
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

# vim: ft=ruby
