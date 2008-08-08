# Methods added to this helper will be available to all templates in the application.

require "dbus"

module ApplicationHelper

def SCRRead (path)
  system_bus = DBus::SystemBus.instance

  # Get the yast service
  yast = system_bus.service("org.opensuse.yast.SCR")

  # Get the object from this service
  objYast = yast.object("/SCR")
  poiSCR = DBus::ProxyObjectInterface.new(objYast, 
                                          "org.opensuse.yast.SCR.Methods")
  poiSCR.define_method("Read", 
                       "in path:(bsv), in arg:(bsv), in opt:(bsv), out ret:(bsv)")

  ret = poiSCR.Read([false, "path", ["s",path] ],
                    [false, "", ["s",""] ], 
                    [false, "", ["s",""] ])
  return  ret[0][2]
end

def SCRWrite (path, value)
  system_bus = DBus::SystemBus.instance

  # Get the yast service
  yast = system_bus.service("org.opensuse.yast.SCR")

  # Get the object from this service
  objYast = yast.object("/SCR")
  poiSCR = DBus::ProxyObjectInterface.new(objYast, 
                                          "org.opensuse.yast.SCR.Methods")
  poiSCR.define_method("Write", 
                       "in path:(bsv), in arg:(bsv), in opt:(bsv), out ret:(bsv)")

  poiSCR.Write([false, "path", ["s",path] ],
               [false, "", ["s",value] ], 
               [false, "", ["s",""] ])
end

def SCRExecute (path, command)
  system_bus = DBus::SystemBus.instance

  # Get the yast service
  yast = system_bus.service("org.opensuse.yast.SCR")

  # Get the object from this service
  objYast = yast.object("/SCR")
  poiSCR = DBus::ProxyObjectInterface.new(objYast, 
                                          "org.opensuse.yast.SCR.Methods")
  poiSCR.define_method("Execute", 
                       "in path:(bsv), in arg:(bsv), in opt:(bsv), out ret:(bsv)")

  ret = poiSCR.Execute([false, "path", ["s",path] ],
                 [false, "", ["s",command] ], 
                 [false, "", ["s",""] ])
  logger.debug " SCRExecute (" + command + ") => " + if ret[0][2]["exit"][2] == 1 then "1"; else "0"; end

  return { :stdout => ret[0][2]["stdout"][2], :exit => ret[0][2]["exit"][2]}
end

end
