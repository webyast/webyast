
include ApplicationHelper

class SystemtimesController < ApplicationController

  before_filter :login_required

  #--------------------------------------------------------------------------------
  #
  # actions
  #
  #--------------------------------------------------------------------------------

  def update
    unless permission_check( "org.opensuse.yast.modules.yapi.time.write")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    
    root = params[:time]
    if root == nil
      render ErrorResult.error(404, 2, "format or internal error") and return
    end
    
    @systemtime = Systemtime.new
    @systemtime.time = root[:time]
    @systemtime.date = root[:date]
    @systemtime.timezone = root[:timezone]
    @systemtime.utcstatus = root[:utcstatus]
    @systemtime.save
    render :show
  end

  def create
    update
  end

  def show
    
    unless permission_check( "org.opensuse.yast.modules.yapi.time.read")
      render ErrorResult.error( 403, 1, "no permission" ) and return
    end

    @systemtime = Systemtime.new
    @systemtime.find

  end

end

