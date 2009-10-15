# = Routing controller
# Provides access to routes settings for authenticated users.
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
      ret = @route.save 
      if ret["exit"]=="0"
	format.xml { head :ok } 
      else  
	  raise RouteError.new ret["error"]
      end
    end
  end


  # Shows route settings. Requires read permission for network YaPI.
  def show
    yapi_perm_check "network.read"
    @route = Route.find(params[:id])

    respond_to do |format|
      format.xml { render :xml => @route.to_xml( :root => "route", :dasherize => false ) }
      format.json { render :json => @route.to_json }
    end
  end

  def index
    routes_a = Route.find(:all).values
    respond_to do |format|
      format.xml { render :xml => routes_a.to_xml( :root => "routes", :dasherize => false ) }
      format.json { render :json => routes_a.to_json }
    end    
  end

end

require 'exceptions'
class RouteError < BackendException
  def initialize(message)
    @message = message
    super("Failed to write route setting with this error: #{@message}.")
  end

  def to_xml
    xml = Builder::XmlMarkup.new({})
    xml.instruct!

    xml.error do
      xml.type "NETWORK_ROUTE_ERROR"
      xml.description @message
      xml.output @message
    end
  end
end
