#!/usr/bin/env ruby

require 'dbus'

# Choose the bus (could also be DBus::session_bus, which is not suitable for a system service)
bus = DBus::system_bus
# Define the service name
service = bus.request_service("example.service")

class ExampleService < DBus::Object
  FILENAME = "/tmp/exampleservicefile"
  # Create an interface.
  dbus_interface "example.service.Interface" do
    # Define D-Bus methods of the service
    # This method reads whole file which name it gets as a parameter and returns its contents
    dbus_method :read, "out contents:s" do |filename|
      f = File.open(FILENAME, "r") {|f| f.read } || ""
    end
    # This method dumps a string into a file
    dbus_method :write, "in contents:s" do |filename,contents|
      File.open(FILENAME, 'w') {|f| f.write(contents) }
    end
  end
end

# Set the object path
obj = ExampleService.new("/example/service/Interface")
# Export it!
service.export(obj)

# Now listen to incoming requests
main = DBus::Main.new
main << bus
main.run
