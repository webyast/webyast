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
  
  def read (path, arg = "")

    ret = @scr.Read([false, "path", ["s",path] ],
                    [false, "string", ["s",arg] ], 
                    [false, "string", ["s",""] ])
    return  ret[0][2]
  end

  def write (path, value, arg = "")
    @scr.Write([false, "path", ["s",path] ],
               [false, "string", ["s",value] ], 
               [false, "string", ["s",arg] ])
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
		       [false, "string", ["s",command] ], 
		       [false, "string", ["s",""] ])
    resmap = ret[0][2]
    exit = resmap["exit"][2]
    Rails.logger.error " SCRExecute (#{command}) => #{exit}"

    return {
      :stdout => resmap["stdout"][2],
      :stderr => resmap["stderr"][2],
      :exit => exit
    }
  end

end
