##!/usr/bin/ruby

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
  