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

require 'active_support/json'
module BaseModel
  module Serialization
    # serializes model to json
    # as root element uses singular model name
    def to_json(options={},&block)
      super
    end

    # restore model from json
    def from_json(json)
      load(ActiveSupport::JSON.decode(json))
    end

private
    def as_json(options={})
      hash = {}
      Serializer.new(self,options).attributes.each do |attr|
        val = instance_variable_get(attr)
        hash[attr.to_s[1..-1]] = val unless val.nil? #remove nil values
      end
#      hash = { self.class.model_name.singular => hash }
      hash
    end

  end
end
