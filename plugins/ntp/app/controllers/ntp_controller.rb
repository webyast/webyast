class NtpController < ApplicationController

  before_filter :login_required

  def show
   	ntp = Ntp.find

    respond_to do |format|
	    format.xml  { render :xml => ntp.to_xml}
	    format.json { render :json => ntp.to_json }
    end
  end
   
  def update
    root = params["ntp"]
    if root == nil || root == {} 
      raise InvalidParameters.new :ntp => "Missing"
    end
	
    ntp = Ntp.new(root)
  	yapi_perm_check "ntp.synchronize" if ntp.actions[:synchronize]
	  ntp.save	

    show
  end

  # See update
  def create
    update
  end

end
