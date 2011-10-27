#!/usr/bin/env ruby
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
