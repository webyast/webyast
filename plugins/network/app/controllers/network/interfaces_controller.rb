# = Hostname controller
# Provides access to hostname settings for authenticated users.
# Main goal is checking permissions.
class Network::InterfacesController < ApplicationController

  before_filter :login_required
  before_filter(:only => [:index, :show]) { |c|    c.yapi_perm_check "network.read" }
  before_filter(:only => [:create, :update]) { |c| c.yapi_perm_check "network.write"}

  # Sets hostname settings. Requires write permissions for network YaPI.
  def update
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
    @ifce = Interface.find(params[:id])

    respond_to do |format|
      format.html { render :xml => @difce.to_xml( :root => "interfaces", :dasherize => false ) }
      format.xml { render :xml => @ifce.to_xml( :root => "interfaces", :dasherize => false ) }
      format.json { render :json => @ifce.to_json }
    end
  end

  def index
   @interfaces = Interface.find_all
  end

end
