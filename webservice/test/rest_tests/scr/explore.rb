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
  when "u"
    "unsigned int"
  when "o"
    "objectpath"
  when "s"
    "string"
  when "v"
    "variant"
  when "y"
    "byte"
  when "a"
    type2s(ts.shift) + "[]"
  when nil
    "void"
  else
    "?#{x}"
  end
end


def parm2s params
  return "void" if params.empty?
  p = params.shift
  r = "#{type2s p[1]} #{p[0]}"
  unless params.empty?
    r += ", #{parm2s params}"
  end
  r
end

def meth2s meth
  "\t#{parm2s meth.rets} #{meth.name}(#{parm2s meth.params})"
end


def explore_object obj
  puts "Object #{obj.path}"
  obj.interfaces.each do |iface|
    puts "  #{iface}" 
    unless $known_interfaces.include? iface
      obj[iface].methods.each do |k,v|
	puts meth2s(v)
      end
      $known_interfaces << iface
    end
  end
  if obj.subnodes
    obj.subnodes.each do |p|
      path = (obj.path.size == 1) ? "#{obj.path}#{p}" : "#{obj.path}/#{p}"
      explore_object obj.bus.introspect(obj.destination, "#{path}")
    end
  end
end

service = ARGV.shift

if service == "--session"
  bus = DBus::session_bus
  service = ARGV.shift
else
# Get the system bus
  bus = DBus::system_bus
end

puts "Bus #{bus}"

unless service
  $stderr.puts "Usage: ruby explore [--session] <service>"
  $stderr.puts " to explore the system (resp. session) bus"
  $stderr.puts "  where <service> is one of"
  i = 0
  explore_object bus.introspect "org.freedesktop.DBus", "/"
  bus.proxy.ListNames[0].each do |service|
    $stderr.print "#{service}"
    if i % 3 == 0
      $stderr.puts
    else
      $stderr.print ", "
    end
  end
  exit
end




explore_object bus.introspect( service, "/" )
