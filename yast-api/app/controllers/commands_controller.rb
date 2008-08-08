include ApplicationHelper

class CommandsController < ApplicationController
  private
  def init_services
    services = Hash.new
    Lsbservice.all.each do |d|
      begin
        service = Lsbservice.new d
        services[service.name] = service
      rescue # Don't fail on non-existing service. Should be more specific.
      end
    end
    session['services'] = services
  end
  def respond data
    STDERR.puts "Respond #{data.class}"
    if data
      respond_to do |format|
	format.xml do
	  render :xml => data.to_xml
	end
	format.json do
	  render :json => data.to_json
	end
	format.html do
	  render
	end
      end
    else
      render :nothing => true, :status => 404 unless @service # not found
    end
  end
  public

  def index
    id = params[:service_id]
#    STDERR.puts "services/show #{id}"
    init_services unless session['services']
    @service = session['services'][id]
#    STDERR.puts "@service #{@service}"
    respond @service
  end

  def update
    id = params[:id]
    logger.debug "calling services/command #{id}"

    cmd = "/usr/sbin/rc" + params[:service_id] + " " + id
		logger.debug "SetTime cmd #{cmd}"
    ret = SCRExecute(".target.bash_output",cmd)

    if ret[:exit] == 0
      respond_to do |format|
        flash[:notice] = 'Command has been run successfully'
        format.html { redirect_to :back, :action => "show" }
	format.json { head :ok }
	format.xml { head :ok }
      end
    else
      respond_to do |format|
        flash[:notice] = 'Command has NOT been run successfully'
        format.html { redirect_to :back, :action => "show" }
	format.json { head :error }
	format.xml { head :error }
      end
    end
  end

end
