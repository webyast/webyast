class ServicesController < ApplicationController
  before_filter :login_required

  def index
    unless permission_check( "org.opensuse.yast.system.services.read")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    @services = Lsbservice.all
    @services = @services.sort unless params[:sort] == "0"

    @services = @services.map {|svc| {:link => svc} }
  end

  # show the svc including the commands
  def show
    unless permission_check( "org.opensuse.yast.system.services.read")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    id = params[:id]

    begin
      @service = Lsbservice.new id
    rescue Exception => e # Don't fail on non-existing service. Should be more specific.
      logger.debug e
      render ErrorResult.error(404, 106, "no such service") and return
    end
    logger.debug "show@service #{@service.inspect}"
  end
end
