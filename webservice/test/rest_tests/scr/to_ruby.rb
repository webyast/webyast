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

class Array
  def to_ruby
    return self unless self.size == 3
    return nil if self[0]
    type = self[1]
    value = self[2]
    case type
    when "list"
      return value.collect { |v| v.to_ruby }
    when "map"
      return value.merge(value) { |k,v1,v2| v1.to_ruby }
    when "string"
      return value
    when "integer"
      return value
    else
      raise "Can't handle #{type}"
    end
  end
end
