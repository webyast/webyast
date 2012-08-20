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

# This task generates REST API documentation from restdoc/api.txt file
# if it has been found. The generated HTML documentation is stored
# to public/*/restdoc directory. (Plugins set the target by creating
# restdoc directory somewhere in public/ subdirectory.)

desc "Generate REST API documentation using 'restility'"
task :restdoc do

  if File.exist? '/usr/bin/rest_doc'
    # input file in root plugin directory
    api_file = 'restdoc/api.txt'
    doc_target = Dir.glob('public/restdoc/**/').max {|a,b| a.length <=> b.length }

    if File.exists?(api_file) && !doc_target.nil? && File.directory?(doc_target)
	    puts "Generating REST API documentation in #{doc_target}..."

	    `rest_doc #{api_file} -I #{api_file.split('/').first} --html -o #{doc_target}`
      FileUtils.mv File.join(doc_target, "index.html"), File.join(doc_target, "restdoc.html")
    else
      puts "Skipping restdoc: restdoc/api.txt or public/restdoc/**/ not found."
    end
  else
    $stderr.puts 'Error: restility gem is not installed!'
    exit 1
  end
end

