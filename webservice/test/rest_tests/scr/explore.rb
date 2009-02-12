##!/usr/bin/ruby

#
# explore.rb
#
# Explore nodes and interfaces on the D-Bus
#
#

require "dbus"
require "to_ruby"

$known_interfaces = Array.new

#     Mount (#<DBus::Method:0x7fa823afab40 @name="Mount", @rets=[["return_code", "i"]], @params=[["mount_point", "s"], ["fstype", "s"], ["extra_options", "as"]]>)

def type2s t
  ts = t.split("")
  x = ts.shift
  case x
  when "("
    ts.pop
    r = Array.new
    ts.each do |y|
      r << type2s(y)
    end
    "{" + r.join(", ") + "}"
  when "b"
    "bool"
  when "i"
    "int"
  when "s"
    "string"
  when "v"
    "variant"
  when "a"
    type2s(ts.shift) + "[]"
  else
    "?#{x}"
  end
end


def parm2s params
  return "" if params.empty?
  p = params.shift
  r = "#{type2s p[1]} #{p[0]}"
  unless params.empty?
    r += ", #{parm2s params}"
  end
  r
end

def meth2s meth
  "#{parm2s meth.rets} #{meth.name}(#{parm2s meth.params})"
end

def explore_subnodes obj, prefix = ""
  obj.subnodes.each do |p|
    path = prefix + "/" + p
    puts "Object #{path}"
    node = obj.bus.introspect( obj.destination, path )
    node.interfaces.each do |iface|
      unless $known_interfaces.include? iface
	puts "  #{iface}" 
	node[iface].methods.each do |k,v|
	  puts meth2s(v)
	end
	$known_interfaces << iface
      end
    end
    explore_subnodes node, path
  end
end

# Get the system bus
bus = DBus::SystemBus.instance

raise "Usage: explore <service>" if ARGV.empty?

# Connect to the SCR service at the root object path
proxy = bus.introspect ARGV.shift, "/"

puts "Proxy <#{proxy}>"
puts "path  <#{proxy.path}>"
puts "destination  <#{proxy.destination}>"
puts "default_iface  <#{proxy.default_iface}>" if proxy.default_iface

explore_subnodes proxy

