#--
# Copyright (c) 2009-2010 Novell, Inc.
# 
# All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
# 
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

require "tempfile"
JSCOMPRESSOR = File.join(RAILS_ROOT, '/script/javascript/jsmin.rb')

def minify(list, output)
   tmp = Tempfile.open('all')
   list.each {|file| open(file) {|f| tmp.write(f.read) } }
   tmp.rewind 
   sh "ruby #{JSCOMPRESSOR} < #{tmp.path} > #{output}"
end

namespace :js do
  javascripts = ['select_dialog.js', 'jquery.quicksearch.js', 'excanvas.js', 'users.js']
  
  Dir.chdir(File.join(RAILS_ROOT, 'public', 'javascripts')) do    
    javascripts.map! {|f| File.join(Dir.pwd, f)}
      #users.js stored in the plugin folder!!!
      #javascripts.push(File.join(File.dirname(__FILE__), '/../../public/javascripts/users.js'))

    file 'users-min.js' => javascripts do | f |
      $dir = File.join(File.dirname(__FILE__), '/../../public/javascripts/min/')
      mkpath($dir);
      minify(f.prerequisites, $dir + f.name)
    end
  end

#  puts "defining task user" #jreidinger: removed because it prints everytime this string, even in silent mode. If it is needed, add it to verbose mode only.
  desc "Minimize javascript source files for production environment"
  task :"users" => ['users-min.js']  do
     puts "Done"
  end
end

task :default => [ :"js:users" ]
