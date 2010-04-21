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

# Get the system bus
system_bus = DBus::SystemBus.instance

# Get the yast service
yast = system_bus.service("org.opensuse.yast.SCR")

# Get the root object from this service
objYast = yast.object("/#{yast.root}")
objYast.introspect
puts objYast.interfaces

poiSCR = objYast.object "org.opensuse.yast.SCR.Methods"
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

p poiSCR.Read([false, "path", ["s",".target.stat"] ],
              [false, "string", ["s","/suse/schubi/.ssh/authorized_keys"] ], 
              [false, "", ["s",""] ])


#p = poiSCR.Execute([false, "path", ["s",".target.bash_output"] ], 
#              [false, "string", ["s","LANG=en.UTF-8 /sbin/yast2 ntp-client status"] ], 
#              [false, "map", ["s","LANG","en.UTF-8"] ])

puts "xxxxxxxxxxxxxxxxxx"
p poiSCR.Execute([false, "path", ["s",".target.bash_output"] ], 
              [false, "string", ["s","LANG=en.UTF-8 /sbin/yast2 --list"] ], 
              [false, "", ["s",""] ])


p  poiSCR.Execute([false, "path", ["s",".target.bash_output"] ], 
              [false, "string", ["s","LANG=en.UTF-8 /sbin/yast2 ntp-client status"] ], 
              [false, "map", ["s","LANG","en.UTF-8"] ])
puts "yyyyyyyyyyyyxxxxxxxxxxxxxxxxxx"
p poiSCR.Read([false, "path", ["s",".target.string"] ],
              [false, "string", ["s","/tmp/YaST2-26169-ewn2Rc/yastOptions"] ], 
              [false, "", ["s",""] ])



#main = DBus::Main.new
#main << system_bus
#main.run

