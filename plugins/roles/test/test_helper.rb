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
# find the rails parent
require File.join(File.dirname(__FILE__), '..', 'config', 'rails_parent')
require File.join(RailsParent.parent, "test","test_helper")

class FakeDbus
	attr_reader :last_perms, :last_user
	def revoke(perms,user)
		@last_perms = perms
		@last_user = user
	end

	def grant(perms,user)
		revoke perms,user
	end
end

