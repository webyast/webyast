#!/usr/bin/ruby
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
	  if m.member == "Finished" || m.member == "Errorcode"
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
        puts "PATCH"
        puts "====="
  	puts u1
  	puts u2
  	puts u3
  @finished= true
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
  @main = MainPkg.new
  @main << system_bus
  @main.run
end

