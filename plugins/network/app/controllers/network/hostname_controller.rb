# = Hostname controller
# Provides access to hostname settings for authenticated users.
# Main goal is checking permissions.

class Network::HostnameController < ApplicationController

  before_filter :login_required
  before_filter(:only => [:show]) { |c| c.yapi_perm_check "network.read" }
  before_filter(:only => [:create, :update]) { |c| c.yapi_perm_check "network.write"}

  # Sets hostname settings. Requires write permissions for network YaPI.
  def update
    root = params[:hostname]
    if root == nil
      raise InvalidParameters.new :hostname => "Missing"
    end
    
    @hostname = Hostname.new(root)
    respond_to do |format|    
	if ( @hostname.save || !@hostname.respond_to?(:errors) )
	  format.xml { head :ok } 
	  else  
	    format.xml { render :xml => @hostname.errors,  :status => :unprocessable_entity } 
	end
    end
  end

  # See update
  def create
    update
  end

  # Shows hostname settings. Requires read permission for network YaPI.
  def show
    @hostname = Hostname.find

    respond_to do |format|
      format.xml { render :xml => @hostname.to_xml( :root => "hostname", :dasherize => false ) }
      format.json { render :json => @hostname.to_json }
    end
  end

end
