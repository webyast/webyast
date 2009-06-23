require "scr"

include ApplicationHelper

class CommandsController < ApplicationController

  before_filter :login_required

  def index
    redirect_to service_path(params[:service_id])
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
