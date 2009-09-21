# = Hostname controller
# Provides access to hostname settings for authenticated users.
# Main goal is checking permissions.
class Network::DnsController < ApplicationController

  before_filter :login_required
  before_filter(:only => [:show]) { |c| c.yapi_perm_check "network.read" }
  before_filter(:only => [:create, :update]) { |c| c.yapi_perm_check "network.write"}

  # Sets hostname settings. Requires write permissions for network YaPI.
  def update
    root = params[:dns]
    if root == nil
      raise InvalidParameters.new [{:name => "Dns", :error => "Missing"}]
    end
    
    root["searches"]=root["searches"].split
    root["nameservers"]=root["nameservers"].split
    
    @dns = DNS.new(root)
    @dns.save
    respond_to do |format|    
	if @dns.save 
	  format.xml { head :ok } 
	  else  
	    format.xml { render :xml => @dns.errors,  :status => :unprocessable_entity } 
	end
    end  end

  # See update
  def create
    update
  end

  # Shows hostname settings. Requires read permission for network YaPI.
  def show
    @dns = DNS.find

    respond_to do |format|
      format.html { render :xml => @dns.to_xml( :root => "dns", :dasherize => false ) }
      format.xml { render :xml => @dns.to_xml( :root => "dns", :dasherize => false ) }
      format.json { render :json => @dns.to_json }
    end
  end

end
