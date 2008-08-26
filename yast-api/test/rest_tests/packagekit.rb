#!/usr/bin/ruby

require "dbus"

require 'socket'
require 'thread'
require 'singleton'

# = MainPkg event loop class.
#
# Class that takes care of handling message and signal events
# asynchronously.  *Note:* This is a native implement and therefore does
# not integrate with a graphical widget set main loop.
class MainPkg
  # Create a new main event loop.
  def initialize
    @buses = Hash.new
  end

  # Add a _bus_ to the list of buses to watch for events.
  def <<(bus)
    @buses[bus.socket] = bus
  end

  # Run the main loop. This is a blocking call!
  def run
    finished = false
    while !finished do
      ready, dum, dum = IO.select(@buses.keys)
      ready.each do |socket|
        b = @buses[socket]
        b.update_buffer
        while m = b.pop_message
          b.process(m)
	  if m.member = "Finished" || m.member = "Errorcode"
            finished = true
          end
        end
      end
    end
  end
end # class MainPkg

system_bus = DBus::SystemBus.instance

packageKit = system_bus.service("org.freedesktop.PackageKit")
obj = packageKit.object("/org/freedesktop/PackageKit")

# Introspect it
obj.introspect

puts obj.interfaces

if obj.has_iface? "org.freedesktop.PackageKit"
  puts "org.freedesktop.PackageKit found"
else
  puts "org.freedesktop.PackageKit not found"
end


obj_with_iface = obj["org.freedesktop.PackageKit"]
tid = obj_with_iface.GetTid
p tid


objTid = packageKit.object(tid[0])

# Introspect it
objTid.introspect

puts objTid.interfaces

if objTid.has_iface? "org.freedesktop.PackageKit.Transaction"
  puts "org.freedesktop.PackageKit.Transaction found"
else
  puts "org.freedesktop.PackageKit.Transaction not found"
end
objTid_with_iface = objTid["org.freedesktop.PackageKit.Transaction"]
objTid.default_iface = "org.freedesktop.PackageKit.Transaction"

@finished = false

objTid.on_signal("Package") do |u1,u2,u3|
  	puts u1
  	puts u2
  	puts u3
        @finished = true
end

objTid.on_signal("Errorcode") do |u1,u2|
  	puts u1
  	puts u2
        @finished = true
end

objTid.on_signal("Finished") do |u1,u2|
  	puts u1
  	puts u2
        @finished = true
end

p objTid_with_iface.GetUpdates("NONE")

if !@finished
  @main = MainPkgss.new
  @main << system_bus
  @main.run
end

