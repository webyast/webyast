# = Interfacescontroller
# Provides access to interface settings for authenticated users.
# Main goal is checking permissions.
class Network::InterfacesController < ApplicationController

  before_filter :login_required
  before_filter(:only => [:index, :show]) { |c|    c.yapi_perm_check "network.read" }
  before_filter(:only => [:create, :update]) { |c| c.yapi_perm_check "network.write"}

  # Sets hostname settings. Requires write permissions for network YaPI.
  def update
    root = params[:interfaces]
    if root == nil
      raise InvalidParameters.new :interfaces => "Missing"
    end
    
    @iface = Interface.new(root)
    respond_to do |format|    
	if @iface.save 
	  format.xml { head :ok } 
	  else  
	    format.xml { render :xml => @iface.errors,  :status => :unprocessable_entity } 
	end
    end
  end

  # Shows hostname settings. Requires read permission for network YaPI.
  def show
    @ifce = Interface.find(params[:id])

    respond_to do |format|
      format.xml { render :xml => @ifce.to_xml( :root => "interfaces", :dasherize => false ) }
      format.json { render :json => @ifce.to_json }
    end
  end

  def index
   ifaces_a = Interface.find(:all).values
   respond_to do |format|
     format.xml { render :xml => ifaces_a.to_xml( :root => "interfaces", :dasherize => false ) }
     format.json { render :json => ifaces_a.to_json }
   end    
  end

end
