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

desc "Test builded package if it can build locally"
task :'build_test'  do
  require File.join(File.dirname(__FILE__), "osc_prepare")
  obs_project, package_name = osc_prepare
  puts "checking out osc package from build"
  begin
    `osc checkout '#{obs_project}' #{package_name}`
    #clean www dir and also clean before copy old entries in osc dir to test if package build after remove some file
    `rm -rf package/www '#{obs_project}/#{package_name}/*'`  
    `cp package/* '#{obs_project}/#{package_name}'`
    Dir.chdir File.join(Dir.pwd, obs_project, package_name) do
      sh "osc build"
    end
    puts "package built"
  ensure
    puts "cleaning"
    `rm -rf '#{obs_project}'`
  end
end


