include ApplicationHelper

class SecuritiesController < ApplicationController
  before_filter :login_required

  public
  # POST /security
  # POST /security.xml
  def create
     update
  end

  # PUT /security/1
  # PUT /security/1.xml
  def update
    unless permission_check( "org.opensuse.yast.system.security.write")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    # get security object and set values
    @security = Security.new
    if params[:security] != nil
      @security.write(params[:security][:firewall], params[:security]\
                    [:firewall_after_startup], params[:security][:ssh])
      logger.debug "UPDATED: #{@security.inspect}"
    else
      render ErrorResult.error(404, 2, "format or internal error") and return
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
    unless permission_check( "org.opensuse.yast.system.security.read")
      render ErrorResult.error(403, 1, "no permission") and return
    else
      @security = Security.new
      @security.update
      logger.debug "SHOW: #{@security.inspect}"
    end
  end
end
