
include ApplicationHelper

class SystemtimeController < ApplicationController

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

  def get_is_utc
    if Scr.read(".sysconfig.clock.HWCLOCK") == "-u" then
      return true
    else
      return false
    end
  end

  def get_time
    ret = Scr.execute("LANG=en.UTF-8 /bin/date")
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
    cmd = "";
    hwclock = Scr.read(".sysconfig.clock.HWCLOCK");
    timezone = get_timezone
    if (timezone.length >0 &&  hwclock!= "--localtime")
      cmd = "TZ=" + timezone + " "
    end

    cmd = cmd + "/sbin/hwclock --set " + hwclock + 
              " --date=\"#{time.month}/#{time.day}/#{time.year}" +
              " #{time.hour}:#{time.min}:#{time.sec}\""

    logger.debug "SetTime cmd #{cmd}"
    Scr.execute(cmd)

    cmd = "/sbin/hwclock --hctosys " + hwclock;

    logger.debug "SetTime cmd #{cmd}"
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
      systemtime = System::SystemTime.new
      if polkit_check( "org.opensuse.yast.webservice.write-systemtime", self.current_account.login) == 0
         if systemtime.update_attributes(params[:systemtime])
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

      if systemtime.error_id == 0
        format.html { redirect_to :action => "show" }
      else
        format.html { render :action => "edit" }
      end

      format.xml do
        render :xml => systemtime.to_xml( :root => "systemtime",
          :dasherize => false )
      end
      format.json do
	render :json => systemtime.to_json
      end
    end
  end

  def show

    @systemtime = System::SystemTime.new

    if polkit_check( "org.opensuse.yast.webservice.read-systemtime", self.current_account.login) == 0
       @systemtime.currenttime = get_time
       @systemtime.is_utc = get_is_utc
       @systemtime.timezone = get_timezone
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
          if ( polkit_check( "org.opensuse.yast.webservice.read-systemtime", self.current_account.login) == 0 or
               polkit_check( "org.opensuse.yast.webservice.read-systemtime-isutc", self.current_account.login) == 0 ) then
             @systemtime.is_utc = get_is_utc
          else
             @systemtime.error_id = 1
             @systemtime.error_string = "no permission"
          end
        when "currenttime"
          if ( polkit_check( "org.opensuse.yast.webservice.read-systemtime", self.current_account.login) == 0 or
               polkit_check( "org.opensuse.yast.webservice.read-systemtime-currenttime", self.current_account.login) == 0 )
             @systemtime.currenttime = get_time
          else
             @systemtime.error_id = 1
             @systemtime.error_string = "no permission"
          end
        when "timezone"
          if ( polkit_check( "org.opensuse.yast.webservice.read-systemtime", self.current_account.login) == 0 or
               polkit_check( "org.opensuse.yast.webservice.read-systemtime-timezone", self.current_account.login) == 0 )
             @systemtime.timezone = get_timezone
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
          render :file => "#{RAILS_ROOT}/app/views/systemtime/show.html.erb"
        end
      end      
    else
      #PUT
      respond_to do |format|
        @systemtime = System::SystemTime.new
        if @systemtime.update_attributes(params[:systemtime])
          logger.debug "UPDATED: #{@systemtime.inspect}"
          case params[:id]
            when "is_utc"
              if ( polkit_check( "org.opensuse.yast.webservice.write-systemtime", self.current_account.login) == 0 or
                   polkit_check( "org.opensuse.yast.webservice.write-systemtime-isutc", self.current_account.login) == 0 ) then
                 set_is_utc @systemtime.is_utc
              else
                 @systemtime.error_id = 1
                 @systemtime.error_string = "no permission"
              end
            when "currenttime"
              if ( polkit_check( "org.opensuse.yast.webservice.write-systemtime", self.current_account.login) == 0 or
                   polkit_check( "org.opensuse.yast.webservice.write-systemtime-currenttime", self.current_account.login) == 0 )
                 set_time @systemtime.currenttime
              else
                 @systemtime.error_id = 1
                 @systemtime.error_string = "no permission"
              end
            when "timezone"
              if ( polkit_check( "org.opensuse.yast.webservice.write-systemtime", self.current_account.login) == 0 or
                   polkit_check( "org.opensuse.yast.webservice.write-systemtime-timezone", self.current_account.login) == 0 )
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

        if @systemtime.error_id == 0
           format.html { redirect_to :action => "show" }
        else
           format.html { render :action => "edit" }
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
