require "scr"

include ApplicationHelper

class CommandsController < ApplicationController

  before_filter :login_required

  def index
    unless permission_check( "org.opensuse.yast.system.services.read")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    id = params[:service_id]

    begin
      @service = Lsbservice.new id
    rescue Exception => e # Don't fail on non-existing service. Should be more specific.
      logger.debug e
      render ErrorResult.error(404, 106, "no such service") and return
    end
    logger.debug "show@service #{@service.inspect}"
    render :show
  end

  def update
    id = params[:id]
    sid = params[:service_id]
    logger.debug "calling services/#{sid}/command #{id}"

    unless permission_check( "org.opensuse.yast.system.services.execute")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    cmd = "/etc/init.d/#{sid}"
    logger.debug "Service cmd #{cmd} #{id}"
    ret = Scr.instance.execute([cmd, id])
    if !ret
      # or 503 service unavailable
      render ErrorResult.error(404, "2", "SCR call failed") and return
    end
    render :xml => ret
  end

end
