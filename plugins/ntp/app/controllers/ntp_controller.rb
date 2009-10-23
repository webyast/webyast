
class NtpController < ApplicationController

  before_filter :login_required

  def show
   	ntp = Ntp.find

    respond_to do |format|
	    format.xml  { render :xml => ntp.actions.to_xml(:root => :actions)}
	    format.json { render :json => ntp.actions.to_json }
    end
  end
   
  def update
    root = params["ntp"]
    if root == nil || root == {} #FIXME exception for this
      raise InvalidParameters.new :ntp => "Missing"
    end
	
    @ntp = Ntp.find

    if root["synchronize"]
      yapi_perm_check "ntp.synchronize"
      @ntp.actions[:synchronize] = true
    end

    @ntp.save
    show
  end

  # See update
  def create
    update
  end

end
