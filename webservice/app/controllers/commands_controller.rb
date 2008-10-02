include ApplicationHelper

class CommandsController < ApplicationController

  before_filter :login_required

  require "scr" 
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
    STDERR.puts "services/show #{id}"
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

    single_policy = "org.opensuse.yast.webservice.execute-services-commands-" + params[:service_id]
    if ( polkit_check( "org.opensuse.yast.webservice.write-services", self.current_account.login) == 0 or
         polkit_check( "org.opensuse.yast.webservice.execute-services-commands", self.current_account.login) == 0 or
         polkit_check( single_policy, self.current_account.login) == 0 )

       cmd = "/usr/sbin/rc" + params[:service_id] + " " + id
       logger.debug "SetTime cmd #{cmd}"
       ret = Scr.execute(cmd)
       @service.error_id = ret[:exit].to_i
       @service.error_string = ret[:stderr]
    else
       @service.error_id = 1
       @service.error_string = "no permission"
    end       

    respond_to do |format|
       if @service.error_id  == 0
          flash[:notice] = 'Command has been run successfully'
          format.html { redirect_to :back, :action => "show" }
       else
          flash[:notice] = 'Command has NOT been run successfully'
          format.html { redirect_to :back, :action => "show" }
       end
       format.xml do
          render :xml => @service.to_xml( :root => "systemtime",
                 :dasherize => false )
       end
       format.json do
          render :json => @service.to_json
       end
    end
  end

end
