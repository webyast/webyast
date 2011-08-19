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

class PrefixedPermission
  attr_accessor :prefix, :short_name, :full_name, :description

  def initialize(permission, description="")
    p = permission
    @full_name = p
    @description = description
    splitted = p.split(".")
    if splitted.length > 1 then
      @prefix = splitted[0..-2].join(".")
      @short_name = splitted.last
    else
      @prefix = p
      @short_name = p
    end
  end
end

class PrefixedPermissions < Hash
  def initialize(prefixed_permissions)
    self.clear
    prefixed_permissions.each do |p|
      if self[p.prefix]
        self[p.prefix] <<  p
      else
        self[p.prefix] = [p]
      end
    end
  end
end
