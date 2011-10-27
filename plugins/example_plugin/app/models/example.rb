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

class Example < BaseModel::Base

  attr_accessor :content

  public
    
    def initialize
      load_content
    end

    #common find as known from ActiveResource and ActiveRecord models
    def self.find(what=:one,options={})
      ret = Example.new
      ret.load_content
      ret
    end

    #update is used for single resource models to perform save on model. see BaseModel#save
    def update
      dbus_obj.write @content
    end

    def load_content
      @content = dbus_obj.read
    end

  private
    
    def dbus_obj
      bus = DBus.system_bus
      ruby_service = bus.service("example.service")
      obj = ruby_service.object("/org/example/service/Interface")
      obj.introspect
      obj.default_iface = "example.service.Interface"
      obj
    end
            
end
