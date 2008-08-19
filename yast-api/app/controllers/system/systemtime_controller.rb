require "dbus"

include ApplicationHelper

class System::SystemtimeController < ApplicationController


#--------------------------------------------------------------------------------
#
#local methods
#
#--------------------------------------------------------------------------------

#
# get
#

  def get_is_utc
    if SCRRead(".sysconfig.clock.HWCLOCK") == "-u" then
      return true
    else
      return false
    end
  end

  def get_time
    ret = SCRExecute(".target.bash_output", "/bin/date")
    ret[:stdout]
  end

  def get_timezone
    return SCRRead(".sysconfig.clock.TIMEZONE")
  end

#
# set
#

  def set_is_utc (utc)
    #set hwclock
    if utc
      hwclock = "-u" 
    else
      hwclock = "--localtime"
    end
    SCRWrite(".sysconfig.clock.HWCLOCK", hwclock)
  end

  def set_time (time)
    #set time
    cmd = "";
    hwclock = SCRRead(".sysconfig.clock.HWCLOCK");
    timezone = get_timezone.length
    if (timezone.length >0 &&  hwclock!= "--localtime")
      cmd = "TZ=" + timezone + " "
    end

    cmd = cmd + "/sbin/hwclock --set " + hwclock + 
              " --date=\"#{systemtime.systemtime.month}/#{systemtime.systemtime.day}/#{systemtime.systemtime.year}" +
              " #{systemtime.systemtime.hour}:#{systemtime.systemtime.min}:#{systemtime.systemtime.sec}\""

    logger.debug "SetTime cmd #{cmd}"
    SCRExecute(".target.bash_output",cmd)

    cmd = "/sbin/hwclock --hctosys " + hwclock;

    logger.debug "SetTime cmd #{cmd}"
    SCRExecute(".target.bash_output",cmd)
  end

  def set_timezone (timezone)
    #set timezone
    SCRWrite(".sysconfig.clock.TIMEZONE",timezone)
  end

#--------------------------------------------------------------------------------
#
# actions
#
#--------------------------------------------------------------------------------
	
  def update
    respond_to do |format|
      systemtime = System::SystemTime.new
      if systemtime.update_attributes(params[:system_time])
        logger.debug "UPDATED: #{systemtime.inspect}"

        set_is_utc systemtime.is_utc
        set_timezone systemtime.timezone
        set_time systemtime.systemtime

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

  def show

    @systemtime = System::SystemTime.new

    @systemtime.systemtime = get_time
    @systemtime.is_utc = get_is_utc
    @systemtime.timezone = get_timezone

    respond_to do |format|
      format.xml do
        render :xml => @systemtime.to_xml( :root => "system_time",
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

  def singleValue
    if request.get?
      # GET
      @value = SingleValue.new
      @value.name = params[:id]
      case @value.name
        when "is_utc"
          @value.value = get_is_utc
        when "time"
          @value.value = get_time
        when "timezone"
          @value.value = get_timezone
      end
      respond_to do |format|
        format.xml do
          render :xml => @value.to_xml( :root => "single_value",
            :dasherize => false )
        end
        format.json do
	  render :json => @value.to_json
        end
        format.html do
          render :file => "#{RAILS_ROOT}/app/views/single_values/singleValue.html.erb"
        end
      end      
    else
      #PUT
      respond_to do |format|
        value = SingleValue.new
        if value.update_attributes(params[:single_value])
          logger.debug "UPDATED: #{value.inspect}"
          ok = true
          case value.name
            when "is_utc"
              set_is_utc value.value
            when "time"
              set_time value.value
            when "timezone"
              set_timezone value.value
            else
              logger.error "Wrong ID: #{value.name}"
              ok = false
          end

          format.html { redirect_to :action => "show" }
          if ok
            format.json { head :ok }
            format.xml { head :ok }
          else
            format.json { head :error }
            format.xml { head :error }
          end
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => ntp.errors,
            :status => :unprocessable_entity }
        end
      end
    end
  end

end
