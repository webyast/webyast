require 'systemtime'

# = Systemtime controller
# Provides access to time settings for authentificated users.
# Main goal is checking permissions.
class SystemtimeController < ApplicationController

  before_filter :login_required

  #--------------------------------------------------------------------------------
  #
  # actions
  #
  #--------------------------------------------------------------------------------

  # Sets time settings. Requires write permissions for time YaPI.
  def update
    yapi_perm_check "time.write"
    root = params[:systemtime]
    if root == nil
      logger.error "Response doesn't contain systemtime key"
      raise InvalidParameters.new :timezone => "Missing"
    end
    
    systemtime = Systemtime.new(root)    
    systemtime.save
    show
  end

  # See update
  def create
    update
  end

  # Shows time settings. Requires read permission for time YaPI.
  def show
    yapi_perm_check "time.read"
    systemtime = Systemtime.find

    respond_to do |format|
      format.xml { render  :xml => systemtime.to_xml( :root => "systemtime", :dasherize => false ) }
      format.json { render :json => systemtime.to_json( :root => "systemtime", :dasherize => false ) }
    end

  end

end

