require 'service'

class ServicesController < ApplicationController
  before_filter :login_required

  def index
    yapi_perm_check "services.read"

    @services	= Service.find_all params
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
