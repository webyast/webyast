#--
# Webyast Webservice framework
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

desc "Check syntax of all Ruby (*.rb) files"
task :check_syntax do
    puts "* Starting syntax check..."

    # check all *.rb files
    Dir.glob("**/*.rb").each do |file|

	`ruby -c #{file}`

	if $?.exitstatus != 0
	    puts "ERROR: Syntax error found"
	    exit 1
	end
    end

    puts "* Done"
end

