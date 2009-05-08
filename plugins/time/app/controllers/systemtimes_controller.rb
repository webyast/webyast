
include ApplicationHelper

class SystemtimesController < ApplicationController

  before_filter :login_required

  def initialize
    require "scr"
    @scr = Scr.instance
  end
  
#--------------------------------------------------------------------------------
#
#local methods
#
#--------------------------------------------------------------------------------

#
# get
#

  def get_validtimezones
     retValue = @scr.execute(["/sbin/yast2", "timezone", "list"])
     lines = retValue[:stderr].split "\n"
     ret = []
     lines.each do |l|   
       if not l.empty?
          lang = l.split " "
          ret << " " << lang[0] if lang[0]!="Region:"
       end
     end
     ret
  end

  def get_is_utc
    if @scr.read(".sysconfig.clock.HWCLOCK") == "-u" then
      return true
    else
      return false
    end
  end

  def get_time
    ret = @scr.execute(["/bin/date"])
    ret[:stdout]
  end

  def get_timezone
    return @scr.read(".sysconfig.clock.TIMEZONE")
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
    @scr.write(".sysconfig.clock.HWCLOCK", hwclock)
  end

  def set_time (time)
    #set time
    environment = [];
    hwclock = @scr.read(".sysconfig.clock.HWCLOCK");
    timezone = get_timezone
    if ( not timezone.empty? && hwclock!= "--localtime")
       environment = ["TZ=#{timezone}"]
    end

    cmd = [ "/sbin/hwclock", "--set", hwclock,
              "--date=\"#{time.month}/#{time.day}/#{time.year}",
              "#{time.hour}:#{time.min}:#{time.sec}\""]

    logger.debug "SetTime cmd #{cmd.inspect}"
    @scr.execute(cmd, environment)

    cmd = ["/sbin/hwclock", "--hctosys",  hwclock]

    logger.debug "SetTime cmd #{cmd.inspect}"
    @scr.execute(cmd)
  end

  def set_timezone (timezone)
    #set timezone
    @scr.write(".sysconfig.clock.TIMEZONE",timezone)
  end

#--------------------------------------------------------------------------------
#
# actions
#
#--------------------------------------------------------------------------------
	
  def update
    respond_to do |format|
      systemtime = SystemTime.new
      if permission_check( "org.opensuse.yast.system.time.write")
         if params[:systemtime] != nil
           systemtime.timezone = params[:systemtime][:timezone]
           systemtime.is_utc = params[:systemtime][:is_utc]
           systemtime.currenttime = params[:systemtime][:currenttime]
           logger.debug "UPDATED: #{systemtime.inspect}"

           set_is_utc systemtime.is_utc
           set_timezone systemtime.timezone
           set_time systemtime.currenttime
         else
           systemtime.error_id = 2
           systemtime.error_string = "format or internal error"
         end
      else #no permissions
         systemtime.error_id = 1
         systemtime.error_string = "no permission"
      end

      format.html do
        render :xml => systemtime.to_xml( :root => "systemtime",
          :dasherize => false ), :location => "none" #return xml value only
      end
      format.xml do
        render :xml => systemtime.to_xml( :root => "systemtime",
          :dasherize => false ), :location => "none"
      end
      format.json do
	render :json => systemtime.to_json , :location => "none"
      end
    end
  end

  def create
     update
  end

  def show

    @systemtime = SystemTime.new

    if permission_check( "org.opensuse.yast.system.time.read")
       @systemtime.currenttime = get_time
       @systemtime.is_utc = get_is_utc
       @systemtime.timezone = get_timezone
       @systemtime.validtimezones = get_validtimezones
    else
       @systemtime.error_id = 1
       @systemtime.error_string = "no permission"
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
        render :xml => @systemtime.to_xml( :root => "systemtime",
          :dasherize => false ) #return xml only
      end
    end
  end

  def index
    show
  end


end

