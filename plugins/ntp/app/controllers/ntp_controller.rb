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
    if root == nil || root == {} #FIXME exception for this
      raise InvalidParameters.new :ntp => "Missing"
    end
	
    Ntp.new(root).save
    show
  end

  # See update
  def create
    update
  end

end
