# = Routing controller
# Provides access to hostname settings for authenticated users.
# Main goal is checking permissions.
class Network::RoutesController < ApplicationController

  before_filter :login_required
  before_filter(:only => [:index, :show]) { |c|    c.yapi_perm_check "network.read" }
  before_filter(:only => [:create, :update]) { |c| c.yapi_perm_check "network.write"}

  # Sets route settings. Requires write permissions for network YaPI.
  def update
    root = params[:routes]
    if root == nil
      raise InvalidParameters.new :routes => "Missing"
    end
    @route = Route.find(root[:id])
    @route.via = root[:via]
    respond_to do |format|    
	if @route.save 
	  format.xml { head :ok } 
	  else  
	    format.xml { render :xml => @route.errors,  :status => :unprocessable_entity } 
	end
    end
  end


  # Shows route settings. Requires read permission for network YaPI.
  def show
    yapi_perm_check "network.read"
    @route = Route.find(params[:id])

    respond_to do |format|
      format.html { render :xml => @route.to_xml( :root => "route", :dasherize => false ) }
      format.xml { render :xml => @route.to_xml( :root => "route", :dasherize => false ) }
      format.json { render :json => @route.to_json }
    end
  end

  def index
    routes_a = Route.find(:all).values
    respond_to do |format|
      format.html { render :xml => routes_a.to_xml( :root => "routes", :dasherize => false ) }
      format.xml { render :xml => routes_a.to_xml( :root => "routes", :dasherize => false ) }
      format.json { render :json => routes_a.to_json }
    end    
  end

end
