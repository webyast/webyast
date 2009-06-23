
include ApplicationHelper

class SystemtimesController < ApplicationController

  before_filter :login_required

#--------------------------------------------------------------------------------
#
# actions
#
#--------------------------------------------------------------------------------

  def update
    unless permission_check( "org.opensuse.yast.system.time.write")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    @systemtime = Systemtime.new
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
    
#    unless permission_check( "org.opensuse.yast.modules.yapi.time.read")
#      render ErrorResult.error( 403, 1, "no permission" ) and return
#    end

    @systemtime = Systemtime.new
    @systemtime.read

  end

end

