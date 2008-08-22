#!/usr/bin/ruby

require "dbus"

system_bus = DBus::SystemBus.instance

# Get the yast service
yast = system_bus.service("org.opensuse.yast.SCR")

# Get the object from this service
objYast = yast.object("/SCR")
objYast.introspect
puts objYast.interfaces

poiSCR = DBus::ProxyObjectInterface.new(objYast, "org.opensuse.yast.SCR.Methods")
poiSCR.define_method("Execute", "in path:(bsv), in arg:(bsv), in opt:(bsv), out ret:(bsv)")

r = poiSCR.Execute([false, "path", ["s",".target.bash_output"] ], 
              [false, "string", ["s","/bin/date +%r"] ], 
              [false, "", ["s",""] ])

p r
puts r[0][2]["stdout"][2]

poiSCR.define_method("Read", "in path:(bsv), in arg:(bsv), in opt:(bsv), out ret:(bsv)")

p poiSCR.Read([false, "path", ["s",".sysconfig.language.RC_LANG"] ], 
              [false, "", ["s",""] ], 
              [false, "", ["s",""] ])
p poiSCR.Read([false, "path", ["s",".sysconfig.clock.TIMEZONE"] ],
              [false, "", ["s",""] ], 
              [false, "", ["s",""] ])
p poiSCR.Read([false, "path", ["s",".sysconfig.clock.DEFAULT_TIMEZONE"] ],
              [false, "", ["s",""] ], 
              [false, "", ["s",""] ])

r = poiSCR.Read([false, "path", ["s",".sysconfig.clock.DEFAULT_TIMEZONE"] ],
              [false, "", ["s",""] ], 
              [false, "", ["s",""] ])
puts r[0][2]

#p poiSCR.Read([false, "path", ["s",".etc.ntp_conf.all"] ],
#              [false, "", ["s",""] ], 
#              [false, "", ["s",""] ])


p = poiSCR.Execute([false, "path", ["s",".target.bash_output"] ], 
              [false, "string", ["s","LANG=en.UTF-8 /sbin/yast2 ntp-client status"] ], 
              [false, "map", ["s","LANG","en.UTF-8"] ])


#main = DBus::Main.new
#main << system_bus
#main.run

