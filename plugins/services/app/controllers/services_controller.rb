class ServicesController < ApplicationController
  before_filter :login_required

  def index
    unless permission_check( "org.opensuse.yast.system.services.read")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    lservices = Lsbservice.all
    lservices = lservices.sort unless params[:sort] == "0"
    @services = lservices.map {|svc| {:link => svc} }
  end

  # show the svc including the commands
  def show
    redirect_to service_commands_path(params[:id])
  end
end
