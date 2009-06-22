
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
     return [] if retValue[:exit] != 0
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
    return "" if ret[:exit] != 0
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

  def set_time (date, time)
    #set time
    environment = [];
    hwclock = @scr.read(".sysconfig.clock.HWCLOCK");
    timezone = get_timezone
    if ( not timezone.empty? && hwclock!= "--localtime")
       environment = ["TZ=#{timezone}"]
    end

    cmd = [ "/sbin/hwclock", "--set", hwclock,
              "--date=\"#{date} #{time}\""]

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
    unless permission_check( "org.opensuse.yast.system.time.write")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    @systemtime = SystemTime.new
    if params[:time] != nil
      @systemtime.timezone = params[:time][:timezone]
      @systemtime.is_utc = params[:time][:is_utc]
      @systemtime.currenttime = params[:time][:currenttime]
      @systemtime.date = params[:time][:date]
      logger.debug "UPDATED: #{@systemtime.inspect}"

      time = Time.parse(@systemtime.currenttime).strftime("%H:%M:%S")
      date = Time.parse(@systemtime.date).strftime("%m/%d/%y")
      if @systemtime.timezone.blank? or
         @systemtime.is_utc.nil? or    # don't use blank? for boolean
         @systemtime.currenttime.blank? or
         @systemtime.date.blank?
        render ErrorResult.error(404, 2, "format or internal error") and return
      end
      set_is_utc @systemtime.is_utc
      set_timezone @systemtime.timezone
      set_time(date, time)
    else
      render ErrorResult.error(404, 2, "format or internal error") and return
    end
    render :show
  end

  def create
     update
  end

  def show

    @systemtime = SystemTime.new

    unless permission_check( "org.opensuse.yast.system.time.read")
      render ErrorResult.error( 403, 1, "no permission" ) and return
    else
      datetime = Time.parse get_time #!!!umwandeln
      @systemtime.currenttime = datetime.strftime("%H:%M")
      @systemtime.date = datetime.strftime("%d/%m/%Y")
      @systemtime.is_utc = get_is_utc
      @systemtime.timezone = get_timezone
      @systemtime.validtimezones = get_validtimezones
      if @systemtime.currenttime.blank? or
         @systemtime.is_utc.nil? or     # don't use blank? for boolean
         @systemtime.timezone.blank? or
         @systemtime.validtimezones.blank? or
         @systemtime.date.blank?
        render ErrorResult.error( 404, 1, "Cannot get time information" ) and return
      end
    end
  end

end

