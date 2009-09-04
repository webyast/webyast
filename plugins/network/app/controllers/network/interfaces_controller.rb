# = Hostname controller
# Provides access to hostname settings for authenticated users.
# Main goal is checking permissions.
class Network::InterfacesController < ApplicationController

  before_filter :login_required

  # Sets hostname settings. Requires write permissions for network YaPI.
  def update
    unless permission_check( "org.opensuse.yast.modules.yapi.network.write")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    
    root = params[:interfaces]
    if root == nil
      render ErrorResult.error(404, 2, "format or internal error") and return
    end
    
    @iface = Interface.new(root)
    @iface.save
    render :show
  end

  # See update
  def create
    update
  end

  # Shows hostname settings. Requires read permission for network YaPI.
  def show
    
    unless permission_check( "org.opensuse.yast.modules.yapi.network.read")
      render ErrorResult.error( 403, 1, "no permission" ) and return
    end

    @ifce = Interface.find(params[:id])

    respond_to do |format|
      format.html { render :xml => @difce.to_xml( :root => "interfaces", :dasherize => false ) }
      format.xml { render :xml => @ifce.to_xml( :root => "interfaces", :dasherize => false ) }
      format.json { render :json => @ifce.to_json }
    end
  end

end
