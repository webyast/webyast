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


# add rename_task method to Rake::Application
# it has an internal hash with name -> Rake::Task mapping
module Rake
    class Application
	def rename_task(task, oldname, newname)
	    if @tasks.nil?
		@tasks = {}
	    end

	    @tasks[newname.to_s] = task

	    if @tasks.has_key? oldname
		@tasks.delete oldname
	    end
	end
    end
end

# add new rename method to Rake::Task class
# to rename a task
class Rake::Task
    def rename(new_name)
	if !new_name.nil?
	    old_name = @name

	    if old_name == new_name
		return
	    end

	    @name = new_name.to_s
	    application.rename_task(self, old_name, new_name)
	end
    end
end

# vim: ft=ruby
