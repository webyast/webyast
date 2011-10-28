#!/usr/bin/env ruby

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


require 'rubygems'
require 'dbus'

# Choose the bus (could also be DBus::session_bus, which is not suitable for a system service)
bus = DBus::system_bus
# Define the service name
service = bus.request_service("example.service")

class ExampleService < DBus::Object
  FILENAME = "/var/log/YaST2/example_file"
  # Create an interface.
  dbus_interface "example.service.Interface" do
    # Define D-Bus methods of the service
    # This method reads whole file which name it gets as a parameter and returns its contents
    dbus_method :read, "out contents:s" do
      out = ""
      begin
        File.open(FILENAME, "r") {|f| out = f.read }
      rescue
        out = "<empty>"
      end
      [out] #return value must be array, as DBus allow multiple return value, so it expect array of return values
    end
    # This method dumps a string into a file
    dbus_method :write, "in contents:s" do |contents|
      File.open(FILENAME, 'w') {|f| f.write(contents) } 
      []
    end
  end
end

# Set the object path
obj = ExampleService.new("/org/example/service/Interface")
# Export it!
service.export(obj)

# Now listen to incoming requests
main = DBus::Main.new
main << bus
main.run
