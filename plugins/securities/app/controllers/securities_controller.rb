include ApplicationHelper

class SecuritiesController < ApplicationController

  before_filter :login_required

#  def initialize
#    require "scr"
#    @scr = Scr.instance
#  end

  public
  # POST /security
  # POST /security.xml
  def create
     update
  end

  # PUT /security/1
  # PUT /security/1.xml
  def update
    respond_to do |format|
      @security = Security.new

      if permission_check("org.opensuse.yast.system.security.write")
        if params[:security] != nil
          @security.write(params[:security][:firewall], params[:security][:firewall_after_startup], params[:security][:ssh])
        else
          @security.error_id = 2
          @security.error_string = "format or internal error"
        end
      else #no permission
        @security.error_id = 1
        @security.error_string = "no permission"
      end

      format.html do
        render :xml => @security.to_xml( :root => "security",
          :dasherize => false ), :location => "none" #return xml value only
      end
      format.xml do
        render :xml => @security.to_xml( :root => "security",
          :dasherize => false ), :location => "none"
      end
      format.json do
        render :json => @security.to_json , :location => "none"
      end
    end
  end

  # GET /security
  # GET /security.xml
  def index
    show
  end

  # GET /security/1
  # GET /security/1.xml
  def show
    @security = Security.new
    if permission_check("org.opensuse.yast.system.security.read")
      @security.update
    else
      @security.error_id = 1
      @security.error_string = "no permission"
    end
#    respond_to do |format|
#      format.html do
#        render :xml => @security.to_xml()#:skip_instruct => true)
#      end
#      format.xml do
#        render :xml => @security.to_xml()
#      end
#      format.json do
#        render :json => @security.to_json , :location => "none"
#      end
#    end
  end
end
