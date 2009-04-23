
include ApplicationHelper

module System

class TimeController < ApplicationController

before_filter :login_required

require "scr"

#--------------------------------------------------------------------------------
#
#local methods
#
#--------------------------------------------------------------------------------

#
# get
#

  def get_validtimezones
     ret = Scr.execute(["/sbin/yast2", "timezone", "list"])
     lines = ret[:stderr].split "\n"
     ret = []
     lines.each do |l|   
       if l.length > 0 && l.casecmp("Region: ") == -1
          lang = l.split " "
          ret << " " << lang[0]
       end
     end
     ret
  end

  def get_is_utc
    if Scr.read(".sysconfig.clock.HWCLOCK") == "-u" then
      return true
    else
      return false
    end
  end

  def get_time
    ret = Scr.execute(["/bin/date"])
    ret[:stdout]
  end

  def get_timezone
    return Scr.read(".sysconfig.clock.TIMEZONE")
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
    Scr.write(".sysconfig.clock.HWCLOCK", hwclock)
  end

  def set_time (time)
    #set time
    environment = [];
    hwclock = Scr.read(".sysconfig.clock.HWCLOCK");
    timezone = get_timezone
    if (timezone.length >0 &&  hwclock!= "--localtime")
       environment = ["TZ=#{timezone}"]
    end

    cmd = [ "/sbin/hwclock", "--set", hwclock,
              "--date=\"#{time.month}/#{time.day}/#{time.year}",
              "#{time.hour}:#{time.min}:#{time.sec}\""]

    logger.debug "SetTime cmd #{cmd.inspect}"
    Scr.execute(cmd, environment)

    cmd = ["/sbin/hwclock", "--hctosys",  hwclock]

    logger.debug "SetTime cmd #{cmd.inspect}"
    Scr.execute(cmd)
  end

  def set_timezone (timezone)
    #set timezone
    Scr.write(".sysconfig.clock.TIMEZONE",timezone)
  end

#--------------------------------------------------------------------------------
#
# actions
#
#--------------------------------------------------------------------------------
	
  def update
    respond_to do |format|
      systemtime = SystemTime.new
      if permission_check( "org.opensuse.yast.systemtime.write")
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

    if permission_check( "org.opensuse.yast.systemtime.read")
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

  def singlevalue
    if request.get?
      # GET
      @systemtime = SystemTime.new

      case params[:id]
        when "is_utc"
          if ( permission_check( "org.opensuse.yast.systemtime.read") or
               permission_check( "org.opensuse.yast.systemtime.read-isutc") ) then
             @systemtime.is_utc = get_is_utc
          else
             @systemtime.error_id = 1
             @systemtime.error_string = "no permission"
          end
        when "currenttime"
          if ( permission_check( "org.opensuse.yast.systemtime.read") or
               permission_check( "org.opensuse.yast.systemtime.read-currenttime") )
             @systemtime.currenttime = get_time
          else
             @systemtime.error_id = 1
             @systemtime.error_string = "no permission"
          end
        when "timezone"
          if ( permission_check( "org.opensuse.yast.systemtime.read") or
               permission_check( "org.opensuse.yast.systemtime.read-timezone") )
             @systemtime.timezone = get_timezone
          else
             @systemtime.error_id = 1
             @systemtime.error_string = "no permission"
          end
        when "validtimezones"
          if ( permission_check( "org.opensuse.yast.systemtime.read") or
               permission_check( "org.opensuse.yast.systemtime.read-validtimezones") )
             @systemtime.validtimezones = get_validtimezones
          else
             @systemtime.error_id = 1
             @systemtime.error_string = "no permission"
          end
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
    else
      #PUT
      respond_to do |format|
        @systemtime = SystemTime.new
        if params[:systemtime] != nil
          @systemtime.timezone = params[:systemtime][:timezone]
          @systemtime.is_utc = params[:systemtime][:is_utc]
          @systemtime.currenttime = params[:systemtime][:currenttime]
          logger.debug "UPDATED: #{@systemtime.inspect}"
          case params[:id]
            when "is_utc"
              if ( permission_check( "org.opensuse.yast.systemtime.write") or
                   permission_check( "org.opensuse.yast.systemtime.write-isutc")) then
                 set_is_utc @systemtime.is_utc
              else
                 @systemtime.error_id = 1
                 @systemtime.error_string = "no permission"
              end
            when "currenttime"
              if ( permission_check( "org.opensuse.yast.systemtime.write") or
                   permission_check( "org.opensuse.yast.systemtime.write-currenttime") )
                 set_time @systemtime.currenttime
              else
                 @systemtime.error_id = 1
                 @systemtime.error_string = "no permission"
              end
            when "timezone"
              if ( permission_check( "org.opensuse.yast.systemtime.write") or
                   permission_check( "org.opensuse.yast.systemtime.write-timezone") )
                 set_timezone @systemtime.timezone
              else
                 @systemtime.error_id = 1
                 @systemtime.error_string = "no permission"
              end
            else
              logger.error "Wrong ID: #{params[:id]}"
              @systemtime.error_id = 2
              @systemtime.error_string = "Wrong ID: #{params[:id]}"
          end
        else
           @systemtime.error_id = 2
           @systemtime.error_string = "format or internal error"
        end

        format.html do
            render :xml => @systemtime.to_xml( :root => "systemtime",
                   :dasherize => false ) #return xml only
        end
        format.xml do
            render :xml => @systemtime.to_xml( :root => "systemtime",
                   :dasherize => false )
        end
        format.json do
           render :json => @systemtime.to_json
        end
      end
    end #put
  end
end

end
