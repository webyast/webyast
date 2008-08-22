
include ApplicationHelper

class SystemtimeController < ApplicationController


#--------------------------------------------------------------------------------
#
#local methods
#
#--------------------------------------------------------------------------------

#
# get
#

  def get_is_utc
    if scrRead(".sysconfig.clock.HWCLOCK") == "-u" then
      return true
    else
      return false
    end
  end

  def get_time
    ret = scrExecute(".target.bash_output", "/bin/date")
    ret[:stdout]
  end

  def get_timezone
    return scrRead(".sysconfig.clock.TIMEZONE")
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
    scrWrite(".sysconfig.clock.HWCLOCK", hwclock)
  end

  def set_time (time)
    #set time
    cmd = "";
    hwclock = scrRead(".sysconfig.clock.HWCLOCK");
    timezone = get_timezone.length
    if (timezone.length >0 &&  hwclock!= "--localtime")
      cmd = "TZ=" + timezone + " "
    end

    cmd = cmd + "/sbin/hwclock --set " + hwclock + 
              " --date=\"#{systemtime.currenttime.month}/#{systemtime.currenttime.day}/#{systemtime.currenttime.year}" +
              " #{systemtime.currenttime.hour}:#{systemtime.currenttime.min}:#{systemtime.currenttime.sec}\""

    logger.debug "SetTime cmd #{cmd}"
    scrExecute(".target.bash_output",cmd)

    cmd = "/sbin/hwclock --hctosys " + hwclock;

    logger.debug "SetTime cmd #{cmd}"
    scrExecute(".target.bash_output",cmd)
  end

  def set_timezone (timezone)
    #set timezone
    scrWrite(".sysconfig.clock.TIMEZONE",timezone)
  end

#--------------------------------------------------------------------------------
#
# actions
#
#--------------------------------------------------------------------------------
	
  def update
    respond_to do |format|
      systemtime = System::SystemTime.new
      if systemtime.update_attributes(params[:systemtime])
        logger.debug "UPDATED: #{systemtime.inspect}"

        set_is_utc systemtime.is_utc
        set_timezone systemtime.timezone
        set_time systemtime.currenttime

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

    @systemtime.currenttime = get_time
    @systemtime.is_utc = get_is_utc
    @systemtime.timezone = get_timezone

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

  def index
    show
  end

  def singleValue
    if request.get?
      # GET
      @systemtime = System::SystemTime.new

      case params[:id]
        when "is_utc"
          @systemtime.is_utc = get_is_utc
        when "currenttime"
          @systemtime.currenttime = get_time
        when "timezone"
          @systemtime.timezone = get_timezone
      end
      respond_to do |format|
        format.xml do
          render :xml => @systemtime.to_xml( :root => "systemtime",
            :dasherize => false )
        end
        format.json do
	  render :json => @systemtime.to_json
        end
        format.html do
          render :file => "#{RAILS_ROOT}/app/views/systemtime/show.html.erb"
        end
      end      
    else
      #PUT
      respond_to do |format|
        @systemtime = System::SystemTime.new
        if @systemtime.update_attributes(params[:systemtime])
          logger.debug "UPDATED: #{@systemtime.inspect}"
          ok = true
          case params[:id]
            when "is_utc"
              set_is_utc @systemtime.is_utc
            when "currenttime"
              set_time @systemtime.currenttime
            when "timezone"
              set_timezone @systemtime.timezone
            else
              logger.error "Wrong ID: #{params[:id]}"
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
          format.xml  { render :xml => @systemtime.errors,
            :status => :unprocessable_entity }
        end
      end
    end
  end

end
