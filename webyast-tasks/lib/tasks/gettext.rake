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

#
# Added for Ruby-GetText-Package
#
require 'rake'
require 'fileutils'

desc "Fetch po files from lcn. Parameter: source directory of lcn e.g. ...lcn/trunk/"
task :fetch_po, [:lcn_dir] do |t, args|
  args.with_defaults(:lcn_dir => File.join(File.dirname(__FILE__),"../../../../..", "lcn", "trunk"))  
  puts "Scanning #{args.lcn_dir}"
  spec_files = Dir.glob("package/**/*.spec")
  unless spec_files.empty?
    package_name = File.basename(spec_files.first,".spec")

    po_files = File.join(args.lcn_dir, "**", "*.po")
    Dir.glob(po_files).each {|po_file|
      filename_array = File.basename(po_file).split(".")
      if filename_array[0] == package_name
         destdir = File.join(Dir.pwd, "po", filename_array[1])
         Dir.mkdir destdir unless File.directory?(destdir)
         destfile = File.join(destdir,filename_array[0]+".po")
         puts "copy #{po_file} --> #{destfile}"
         FileUtils.cp(po_file, destfile)
      end
    }
  else
    puts "ERROR: package name not found for #{Dir.pwd}"
  end
end

