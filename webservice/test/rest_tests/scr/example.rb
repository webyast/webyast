##!/usr/bin/ruby

require "dbus"
require "to_ruby"

# Get the system bus
bus = DBus::SystemBus.instance

# Connect to the SCR service at the root object path
proxy = bus.introspect "org.opensuse.yast.SCR", "/"

# proxy.subnodes is a list of object pathes below "/"

# But we know our object path, its "/SCR"

# just a consistency check
raise "Oops, no /SCR object" unless proxy.subnodes.include? "SCR"
    
# now lets look at what /SCR has to offer
# btw, proxy.destination == "org.opensuse.yast.SCR"
scr = bus.introspect proxy.destination, "/SCR"

raise "Can't obtain /SCR object" unless scr

# scr.interfaces is a list of interfaces offered by the object

# But we know our interfacem its "org.opensuse.yast.SCR.Methods"

raise "Oops, no Methods interface" unless scr.interfaces.include? "org.opensuse.yast.SCR.Methods"

interface = scr["org.opensuse.yast.SCR.Methods"]
  
res = interface.Execute([false, "path", ["s", ".target.bash_output"]], [false, "string", ["s", "ls"]], [false,"string",["s","/abuild"]])
puts "ls gives #{res[0].to_ruby}"

res = interface.Read([false, "path", ["s", ".probe.cpu"]], [false, "string", ["s", ""]], [true,"",["s",""]])
cpus = res[0].to_ruby
puts "Found #{cpus.size} cpus:"
cpus.each do |cpu|
  puts "'#{cpu['name']}' running at #{cpu['clock']/1000.0} GHz"
end
