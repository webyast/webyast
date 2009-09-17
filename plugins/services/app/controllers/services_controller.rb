require 'service'

class ServicesController < ApplicationController
  before_filter :login_required

  def index
    yapi_perm_check "services.read"

    begin
	@services	= Service.find_all params
    rescue Exception => e
	render ErrorResult.error(404, 107, e.to_s) and return
    end
  end

  # GET /services/service_name
  # GET /services/service_name.xml
  # GET /services/service_name.json
  def show
    unless permission_check("org.opensuse.yast.modules.yapi.services.read")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    @service = Service.new(params[:id])

    begin
	@service.read_status
    rescue Exception => e
	render ErrorResult.error(404, 108, e.to_s) and return
    end

    respond_to do |format|
	format.html { render :xml => @service.to_xml(:root => 'service', :dasherize => false), :location => "none" } #return xml only
	format.xml  { render :xml => @service.to_xml(:root => 'service', :dasherize => false, :indent => 2), :location => "none" }
	format.json { render :json => @service.to_json, :location => "none" }
    end
  end

  # PUT /services/1.xml
  # Shows service status. Requires execute permission for services YaPI.
  def update
    yapi_perm_check "services.execute"

    begin
      @service = Service.find params[:id]
    rescue Exception => e
      logger.debug e
      render ErrorResult.error(404, 106, "no such service") and return
    end

    begin
      ret	= @service.save(params[:execute])
    rescue Exception => e
      logger.debug e
      render ErrorResult.error(404, @error_id, @error_string) and return
    end

    render :xml => ret
  end

end
