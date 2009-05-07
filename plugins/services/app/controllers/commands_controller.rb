include ApplicationHelper

class CommandsController < ApplicationController

  before_filter :login_required

  private
  def init_services
    services = Hash.new
    Lsbservice.all.each do |d|
      begin
        service = Lsbservice.new d
        services[service.link] = service
      rescue # Don't fail on non-existing service. Should be more specific.
      end
    end
    session['services'] = services
  end
  def respond data
    logger.debug "Respond #{data.class}"
    if data
      respond_to do |format|
	format.xml do
	  render :xml => data.to_xml
	end
	format.json do
	  render :json => data.to_json
	end
	format.html do
	  render :xml => data.to_xml #return xml only
	end
      end
    else
      render :nothing => true, :status => 404 unless @service # not found
    end
  end
  public

  def index
    id = params[:service_id]
    logger.debug "services/show #{id}"
    init_services unless session['services']
    @service = session['services'][id]
    respond @service
  end

  def update
    id = params[:id]
    logger.debug "calling services/command #{id}"

    init_services unless session['services']
    @service = session['services'][params[:service_id]]

    @service.error_id = 0
    @service.error_string = ""

    if permission_check( "org.opensuse.yast.system.services.execute") 
       require "scr"
       cmd = "/usr/sbin/rc" + params[:service_id] 
       logger.debug "Service cmd #{cmd} #{id}"
       ret = Scr.instance.execute([cmd, id])
       @service.error_id = ret[:exit].to_i
       @service.error_string = ret[:stderr]
       if ret[:stdout].size > 0
         @service.error_string += "; " @service.error_string.size > 0
	 @service.error_string +=ret[:stdout]
       end
    else
       @service.error_id = 1
       @service.error_string = "no permission"
    end       
    respond_to do |format|
       format.html do
          render :xml => @service.to_xml( :root => "service", 
                 :dasherize => false ) #return xml only
       end
       format.xml do
          render :xml => @service.to_xml( :root => "service",
                 :dasherize => false )
       end
       format.json do
          render :json => @service.to_json
       end
    end
  end

end
