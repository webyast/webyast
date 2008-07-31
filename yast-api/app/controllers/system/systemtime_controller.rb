require "dbus"

class System::SystemtimeController < ApplicationController
	
  def update
    respond_to do |format|
      systemtime = System::SystemTime.new
      if systemtime.update_attributes(params[:system_time])
        logger.debug "UPDATED: #{systemtime.inspect}"
        system_bus = DBus::SystemBus.instance

        # Get the yast service
        yast = system_bus.service("org.opensuse.yast.SCR")

        # Get the object from this service
        objYast = yast.object("/SCR")
        poiSCR = DBus::ProxyObjectInterface.new(objYast, 
                                                "org.opensuse.yast.SCR.Methods")
        poiSCR.define_method("Write", 
                             "in path:(bsv), in arg:(bsv), in opt:(bsv), out ret:(bsv)")
        poiSCR.define_method("Execute", 
                             "in path:(bsv), in arg:(bsv), in opt:(bsv), out ret:(bsv)")

        #set hwclock
	if systemtime.is_utc
	  hwclock = "-u" 
        else
          hwclock = "--localtime"
        end
        poiSCR.Write([false, "path", ["s",".sysconfig.clock.HWCLOCK"] ], 
                     [false, "string", ["s",hwclock] ], 
                     [false, "", ["s",""] ])

        #set timezone
        poiSCR.Write([false, "path", ["s",".sysconfig.clock.TIMEZONE"] ], 
                     [false, "string", ["s",systemtime.timezone] ], 
                     [false, "", ["s",""] ])

        #set time
	cmd = "";
	if (systemtime.timezone.length >0 && hwclock != "--localtime")
	    cmd = "TZ=" + systemtime.timezone + " "
        end

	cmd = cmd + "/sbin/hwclock --set " + hwclock + 
              " --date=\"#{systemtime.systemtime.month}/#{systemtime.systemtime.day}/#{systemtime.systemtime.year}" +
              " #{systemtime.systemtime.hour}:#{systemtime.systemtime.min}:#{systemtime.systemtime.sec}\""

	logger.debug "SetTime cmd #{cmd}"
        poiSCR.Execute([false, "path", ["s",".target.bash_output"] ], 
                       [false, "string", ["s",cmd] ], 
                       [false, "", ["s",""] ])

	cmd = "/sbin/hwclock --hctosys " + hwclock;

	logger.debug "SetTime cmd #{cmd}"
        poiSCR.Execute([false, "path", ["s",".target.bash_output"] ], 
                       [false, "string", ["s",cmd] ], 
                       [false, "", ["s",""] ])

        format.html { redirect_to :action => "show" }
	format.json { head :ok }
	format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => systemtime.errors,
          :status => :unprocessable_entity }
      end
    end
  end

# Workaround for put-problem
#  def create
#    logger.error("create ....", params[:systemtime][:time])	
#  end

  def show
    system_bus = DBus::SystemBus.instance

    # Get the yast service
    yast = system_bus.service("org.opensuse.yast.SCR")

    # Get the object from this service
    objYast = yast.object("/SCR")
    poiSCR = DBus::ProxyObjectInterface.new(objYast, 
                                            "org.opensuse.yast.SCR.Methods")
    poiSCR.define_method("Read", 
                         "in path:(bsv), in arg:(bsv), in opt:(bsv), out ret:(bsv)")
    poiSCR.define_method("Execute", 
                         "in path:(bsv), in arg:(bsv), in opt:(bsv), out ret:(bsv)")

    @systemtime = System::SystemTime.new

    ret = poiSCR.Execute([false, "path", ["s",".target.bash_output"] ], 
              [false, "string", ["s","/bin/date"] ], 
              [false, "", ["s",""] ])

    @systemtime.systemtime = ret[0][2]["stdout"][2]

    ret = poiSCR.Read([false, "path", ["s",".sysconfig.clock.HWCLOCK"] ],
              [false, "", ["s",""] ], 
              [false, "", ["s",""] ])

    if ret[0][2] == "-u" then
      @systemtime.is_utc = true
    else
      @systemtime.is_utc = false
    end

    ret = poiSCR.Read([false, "path", ["s",".sysconfig.clock.TIMEZONE"] ],
              [false, "", ["s",""] ], 
              [false, "", ["s",""] ])
    @systemtime.timezone = ret[0][2]

    respond_to do |format|
      format.xml do
        render :xml => @systemtime.to_xml( :root => "systemtime",
          :dasherize => false )
      end
      format.json do
	render :json => @systemtime.to_json
      end
      format.html do
        render
      end
    end
  end

end
