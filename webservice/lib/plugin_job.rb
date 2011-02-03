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

class PluginJob < Struct.new(:function_string)
  def perform
    function_array = function_string.split(":")
    raise "Invalid job entry: #{function_string}" if function_array.size < 2
    function_class = (function_array.first).classify
    object = Object.const_get(function_class) rescue $!
    if object.class != NameError && object.respond_to?(function_array[1])
      Rails.logger.info "Calling job: #{function_string}"
#      ret = object.method(function_array[1]).call
      ret = object.send(function_array[1])
      Rails.logger.info "Job returns: #{ret.inspect}"
    end
  end    
end  

