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

require 'fileutils'

desc "Granting policies for root and for the user #{ENV['USER']}"
task :grant_policies do |t|
  user = ENV['USER']
  puts "Running from #{__FILE__} with user: #{user}"
  puts "You must deploy webyast first!" and return unless File.exists? "/usr/sbin/grantwebyastrights"
  system "/usr/sbin/grantwebyastrights --user root --action grant >/dev/null 2>&1"
  raise "Error on execute '/usr/sbin/grantwebyastrights --user root --action grant '" if $?.exitstatus != 0
  system "/usr/sbin/grantwebyastrights --user #{user} --action grant >/dev/null 2>&1"
  raise "Error on execute '/usr/sbin/grantwebyastrights --user #{user} --action grant '" if $?.exitstatus != 0

  #granting special rights defined in the spec files
  `find . -name "*.spec"`.each_line { |spec_file|
    `egrep "grantwebyastrights" #{spec_file}`.each_line { |command|
      unless command.lstrip.start_with?("#")
        if command.include?("--action grant") && command.include?("--policy") && command.include?("%{webyast_user}")
          command["%{webyast_user}"] = user
          puts "Calling: #{command}"
	  system command
        end
      end
    }
  }
end

