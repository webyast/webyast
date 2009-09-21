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
    yapi_perm_check "time.write"
    
    root = params[:time]
    if root == nil
      raise InvalidParameters.new [{:name => "Timezone", :error => "Missing"}]
    end
    
    @systemtime = Systemtime.create_from_xml(root)
    @systemtime.save
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
      format.html { render :xml => systemtime.to_xml( :root => "systemtime", :dasherize => false ) }
      format.xml { render  :xml => systemtime.to_xml( :root => "systemtime", :dasherize => false ) }
      format.json { render :json => systemtime.to_json( :root => "systemtime", :dasherize => false ) }
    end

  end

end

