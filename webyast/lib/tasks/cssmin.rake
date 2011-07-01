#--
# Webyast Webclient framework
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

require "tempfile"
require "cssmin"

#require File.join(File.dirname(__FILE__), "..", "cssmin.rb")

CSS_PATH = File.join(RAILS_ROOT, '/public/stylesheets')
OUTPUT_FILE = 'css-min.css'

def min(list, output)
  tmp = Tempfile.open('all')
  list.each {|file| open(file) {|f| tmp.write(f.read) }}
  open(tmp.path) { |tmp| File.open(output, 'w') {|out| out.write(CSSMin.minify(tmp)) }}
end

namespace :css do

  desc 'Minimize CSS files'
  task :"min" do
    Dir.chdir(CSS_PATH) do
      files = Dir.glob("*.css")
      files.map! {|f| File.join(Dir.pwd, f)}

      output = File.join(Dir.pwd, OUTPUT_FILE)
      #do not compress already minified file
      files.delete(output)
      puts files.sort.join ",\n"
      min(files.sort, output)
    end
    puts "\nPath to output file: #{CSS_PATH}"
    puts "\n####################: #{File.join(File.dirname(__FILE__), "..", "cssmin.rb")}"
  end
end
