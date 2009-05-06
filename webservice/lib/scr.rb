#
# Scr - access to YaST SCR api via D-Bus
#
# This class encapsulates access methods to
# the org.opensuse.yast.SCR D-Bus service and
# its /SCR object, offering the org.opensuse.yast.SCR.Methods interface
#
#

class Scr
  include Singleton
  require "dbus"
  require "logger"

  def initialize
    @bus = DBus::SystemBus.instance
    raise "Cannot access D-Bus SystemBus" unless @bus
    @proxy = @bus.introspect( "org.opensuse.yast.SCR", "/SCR" )
    raise "Cannot find /SCR for org.opensuse.yast.SCR" unless @proxy
    @scr = @proxy["org.opensuse.yast.SCR.Methods"] 
    raise "/SCR object does not provide org.opensuse.yast.SCR.Methods interface" unless @scr    
  end
  
  def read (path)

    ret = @scr.Read([false, "path", ["s",path] ],
                    [false, "", ["s",""] ], 
                    [false, "", ["s",""] ])
    return  ret[0][2]
  end

  def read_arg (path,argument)
    ret = @scr.Read([false, "path", ["s",path] ],
                    [false, "string", ["s",argument] ], 
                    [false, "", ["s",""] ])
    return  ret[0][2]
  end

  def write (path, value)
    @src.Write([false, "path", ["s",path] ],
               [false, "", ["s",value] ], 
               [false, "", ["s",""] ])
  end

  def execute (arguments, environment=[] )

    #sanitize arguments
    # FIXME: use regexp
    whitelist = ("a".."z").to_a.to_s + ("A".."Z").to_a.to_s + ("0".."9").to_a.to_s + "_-/=:.,\"<> "
    arguments.each do |arg|
      for i in (0..arg.size-1) do
	return { :stdout =>"", :stderr => "#{arg}: only a..z A..Z 0..9,_-/=.:<> are allowed", :exit => 2} if whitelist.index(arg[i]).nil?
      end
    end

    #note environment array will not be set by the user. So no check is needed.

    command = "LANG=en.UTF-8"
    command += environment.join(" ")
    command += " /usr/lib/YaST2/bin/tty_wrapper "
    command += arguments.join(" ")
    command += " </dev/null"

    ret = @scr.Execute([false, "path", ["s",".target.bash_output"] ],
		       [false, "", ["s",command] ], 
		       [false, "", ["s",""] ])

    log.error " SCRExecute (" + command + ") => " + if ret[0][2]["exit"][2] == 1 then "1"; else "0"; end

    return { :stdout => ret[0][2]["stdout"][2], :stderr => ret[0][2]["stderr"][2], :exit => ret[0][2]["exit"][2]}
  end

end
