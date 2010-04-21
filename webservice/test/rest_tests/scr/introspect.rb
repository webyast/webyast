##!/usr/bin/ruby
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


require "rexml/document"
require "dbus"

# Get the system bus
bus = DBus::SystemBus.instance
connection = "org.opensuse.yast.SCR"
proxy = bus.introspect connection, "/"

  puts "Proxy <#{proxy}>"
  puts "methods  <#{(proxy.methods - Object.methods).inspect}>"
  puts "bus  <#{proxy.bus}>"
  puts "path  <#{proxy.path}>"
  puts "destination  <#{proxy.destination}>"
  puts "default_iface  <#{proxy.default_iface}>"
  scrnode = nil
  scrif = nil
  proxy.subnodes.each do |path|
    node = bus.introspect proxy.destination, "/#{path}"
    scrnode = node if path == "SCR"
    puts "  #{path}: #{node}"
    puts "  #{(node.methods - Object.methods).inspect}"
    node.interfaces.each do |iface|
      interface = node[iface]
      scrif = interface if iface == "org.opensuse.yast.SCR.Methods"
      puts "    #{iface}: #{interface}"
      puts "    #{interface.methods.inspect}"
      puts "    #{(interface.public_methods - interface.class.methods).inspect}"
    end
  end
  puts "Calling #{scrif.methods['Execute'].inspect}"
  scrif.Execute(".bin.bash", "ls")
  