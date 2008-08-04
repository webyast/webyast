require "dbus"

include ApplicationHelper

class System::SystemtimeController < ApplicationController
	
  def update
    respond_to do |format|
      systemtime = System::SystemTime.new
      if systemtime.update_attributes(params[:system_time])
        logger.debug "UPDATED: #{systemtime.inspect}"

        #set hwclock
	if systemtime.is_utc
	  hwclock = "-u" 
        else
          hwclock = "--localtime"
        end
        SCRWrite(".sysconfig.clock.HWCLOCK", hwclock)

        #set timezone
        SCRWrite(".sysconfig.clock.TIMEZONE",systemtime.timezone)

        #set time
	cmd = "";
	if (systemtime.timezone.length >0 && hwclock != "--localtime")
	    cmd = "TZ=" + systemtime.timezone + " "
        end

	cmd = cmd + "/sbin/hwclock --set " + hwclock + 
              " --date=\"#{systemtime.systemtime.month}/#{systemtime.systemtime.day}/#{systemtime.systemtime.year}" +
              " #{systemtime.systemtime.hour}:#{systemtime.systemtime.min}:#{systemtime.systemtime.sec}\""

	logger.debug "SetTime cmd #{cmd}"
        SCRExecute(".target.bash_output",cmd)

	cmd = "/sbin/hwclock --hctosys " + hwclock;

	logger.debug "SetTime cmd #{cmd}"
        SCRExecute(".target.bash_output",cmd)

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

    @systemtime = System::SystemTime.new

    @systemtime.systemtime = SCRExecute(".target.bash_output", "/bin/date")

    if SCRRead(".sysconfig.clock.HWCLOCK") == "-u" then
      @systemtime.is_utc = true
    else
      @systemtime.is_utc = false
    end

    @systemtime.timezone = SCRRead(".sysconfig.clock.TIMEZONE")

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
