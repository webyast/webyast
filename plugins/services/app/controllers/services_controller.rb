require 'service'

class ServicesController < ApplicationController
  before_filter :login_required

  def index
    unless permission_check("org.opensuse.yast.modules.yapi.services.read")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    @services	= Service.find_all
  end

  # Shows service status. Requires read permission for services YaPI.
  def show
    unless permission_check("org.opensuse.yast.modules.yapi.services.get")
      render ErrorResult.error( 403, 1, "no permission" ) and return
    end

    id = params[:id]
    begin
      @service = Service.find id
    rescue Exception => e # Don't fail on non-existing service. Should be more specific.
      logger.debug e
      render ErrorResult.error(404, 106, "no such service") and return
    end
    logger.debug "show@service #{@service.inspect}"
  end

  # Change the service status. Requires write permissions for services YaPI.
  # POST /services
  def create

    unless permission_check( "org.opensuse.yast.modules.yapi.services.execute")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    services	= params[:services]
    id		= services[:name]
    begin
      @service = Service.find id
    rescue Exception => e
      logger.debug e
      render ErrorResult.error(404, 106, "no such service") and return
    end

    @service.execute	= services[:execute]

    begin
      @service.save
    rescue Exception => e
      logger.debug e
      render ErrorResult.error(404, @error_id, @error_string) and return
    end

    render :show
  end

end
