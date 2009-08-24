require 'service'

class ServicesController < ApplicationController
  before_filter :login_required

  def index
    unless permission_check("org.opensuse.yast.modules.yapi.services.read")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    begin
	@services	= Service.find_all params
    rescue Exception => e
	render ErrorResult.error(404, 107, "cannot read services") and return
    end
  end

  # PUT /services/1.xml
  # Shows service status. Requires execute permission for services YaPI.
  def update

    unless permission_check( "org.opensuse.yast.modules.yapi.services.execute")
      render ErrorResult.error(403, 1, "no permission") and return
    end

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
