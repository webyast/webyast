class Scr
  require "dbus"
  require "logger"

def Scr.read (path)

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

def Scr.readArg (path,argument)
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
                    [false, "string", ["s",argument] ], 
                    [false, "", ["s",""] ])
  return  ret[0][2]
end

def Scr.write (path, value)
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

def Scr.execute (argument, environment=[] )
  command = "LANG=en.UTF-8"
  environment.each do |env|
    command += " #{env}"
  end
  command += " /usr/lib/YaST2/bin/tty_wrapper "
  argument.each do |arg|
    command += " #{arg}"
  end

  command += " </dev/null"
  system_bus = DBus::SystemBus.instance

  # Get the yast service
  yast = system_bus.service("org.opensuse.yast.SCR")

  # Get the object from this service
  objYast = yast.object("/SCR")
  poiSCR = DBus::ProxyObjectInterface.new(objYast, 
                                          "org.opensuse.yast.SCR.Methods")
  poiSCR.define_method("Execute", 
                       "in path:(bsv), in arg:(bsv), in opt:(bsv), out ret:(bsv)")

  ret = poiSCR.Execute([false, "path", ["s",".target.bash_output"] ],
                 [false, "", ["s",command] ], 
                 [false, "", ["s",""] ])

  STDERR.puts " SCRExecute (" + command + ") => " + if ret[0][2]["exit"][2] == 1 then "1"; else "0"; end

  return { :stdout => ret[0][2]["stdout"][2], :stderr => ret[0][2]["stderr"][2], :exit => ret[0][2]["exit"][2]}
end

end
