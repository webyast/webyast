require 'systemtime'

# = Systemtime controller
# Provides access to time settings for authentificated users.
# Main goal is checking permissions.
class SystemtimesController < ApplicationController

  before_filter :login_required

  #--------------------------------------------------------------------------------
  #
  # actions
  #
  #--------------------------------------------------------------------------------

  # Sets time settings. Requires write permissions for time YaPI.
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

  # See update
  def create
    update
  end

  # Shows time settings. Requires read permission for time YaPI.
  def show
    
    unless permission_check( "org.opensuse.yast.modules.yapi.time.read")
      render ErrorResult.error( 403, 1, "no permission" ) and return
    end

    @systemtime = Systemtime.find

  end

end

