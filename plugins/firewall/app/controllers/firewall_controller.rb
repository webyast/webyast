require 'firewall'

class FirewallController < ApplicationController

  before_filter :login_required

  def show
    yapi_perm_check "firewall.read"
    firewall = Firewall.find

    respond_to do |format|
      format.xml { render  :xml => firewall.to_xml( :dasherize => false ) }
      format.json { render :json => firewall.to_json( :dasherize => false ) }
    end
  end
end
