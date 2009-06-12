require "scr"

include ApplicationHelper

class CommandsController < ApplicationController

  before_filter :login_required

  private
  def init_services
    services = Hash.new
    Lsbservice.mock_each do |d|
      begin
        service = Lsbservice.new d
        services[service.link] = service
      rescue # Don't fail on non-existing service. Should be more specific.
      end
    end
    session['services'] = services
  end

  public

  def index
    unless permission_check( "org.opensuse.yast.system.services.read")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    id = params[:service_id]
    logger.debug "services/show #{id}"
    init_services unless session['services']
    @service = session['services'][id]
    render :show
  end

  def update
    id = params[:id]
    logger.debug "calling services/command #{id}"

    unless permission_check( "org.opensuse.yast.system.services.execute")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    init_services unless session['services']
    @service = session['services'][params[:service_id]]

    cmd = "/usr/sbin/rc" + params[:service_id] 
    logger.debug "Service cmd #{cmd} #{id}"
    ret = Scr.instance.execute([cmd, id])
    if !ret    
      render ErrorResult.error(404, "2", "SCR call failed") and return
    end
    if ret[:exit].to_i != 0
      error_string = ret[:stderr]
      if ret[:stdout].size > 0
        error_string += "; " 
        error_string +=ret[:stdout]
      end
      render ErrorResult.error(404, ret[:exit].to_i, error_string) and return
    end
    render :show
  end

end
