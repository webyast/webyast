
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
    cmd = @scr.read(".sysconfig.clock.HWCLOCK")
    case cmd
      when "-u"    # is utc
        return true
      when nil     # failure
        return nil
      else         # no utc
        return false
    end
  end

  def get_time
    ret = @scr.execute(["/bin/date"])
    return nil if ret[:exit] != 0
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
#    cmd = ["/bin/date", "--set=\"#{date} #{time}\""]
#    logger.debug "SetTime cmd #{cmd.inspect}"
#    @scr.execute(cmd)
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
#      @systemtime.currenttime = params[:time][:currenttime]
#      @systemtime.date = params[:time][:date]

      begin
        @systemtime.currenttime = Time.parse(params[:time][:currenttime]).strftime("%H:%M:%S")
        @systemtime.date = Time.parse(params[:time][:date]).strftime("%m/%d/%y")
      rescue
        render ErrorResult.error(404, 2, "format error in time or date") and return
      end
      logger.debug "UPDATED: #{@systemtime.inspect}"
      if @systemtime.timezone.blank? or
         @systemtime.is_utc.nil?     # don't use blank? for boolean
        render ErrorResult.error(404, 2, "format or internal error") and return
      end
      set_is_utc @systemtime.is_utc
      set_timezone @systemtime.timezone
      set_time(@systemtime.date, @systemtime.currenttime)
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
      begin
        datetime = Time.parse get_time
      rescue
        render ErrorResult.error( 404, 1, "Cannot parse time information" ) and return
      end
      @systemtime.currenttime = datetime.strftime("%H:%M")
      @systemtime.date = datetime.strftime("%d/%m/%Y")
      @systemtime.is_utc = get_is_utc
      @systemtime.timezone = get_timezone
      @systemtime.validtimezones = get_validtimezones
      if @systemtime.is_utc.nil?      # don't use blank? for boolean
         @systemtime.timezone.blank? or
         @systemtime.validtimezones.blank?
        render ErrorResult.error( 404, 1, "Cannot get time information" ) and return
      end
    end

  end

end

